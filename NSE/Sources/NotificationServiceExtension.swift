//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import UserNotifications

// The lifecycle of the NSE looks something like the following:
//  1)  App receives notification
//  2)  System creates an instance of the extension class
//      and calls `didReceive` in the background
//  3)  Extension processes messages / displays whatever
//      notifications it needs to
//  4)  Extension notifies its work is complete by calling
//      the contentHandler
//  5)  If the extension takes too long to perform its work
//      (more than 30s), it will be notified and immediately
//      terminated
//
// Note that the NSE does *not* always spawn a new process to
// handle a new notification and will also try and process notifications
// in parallel. `didReceive` could be called twice for the same process,
// but it will always be called on different threads. It may or may not be
// called on the same instance of `NotificationService` as a previous
// notification.

class NotificationServiceExtension: UNNotificationServiceExtension {
    static let receivedWhileOfflineNotificationID = "io.element.elementx.receivedWhileOfflineNotification"
    
    private static var targetConfiguration: Target.ConfigurationResult?
    private static var hasHandledFirstNotificationSinceBoot = false
    
    private let settings: CommonSettingsProtocol = AppSettings()
    private let appHooks: AppHooks
    
    private var notificationHandler: NotificationHandler?
    private let keychainController = KeychainController(service: .sessions,
                                                        accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)
    
    private var cancellables: Set<AnyCancellable> = []
    
    /// We can make the whole NSE a MainActor after https://github.com/swiftlang/swift-evolution/blob/main/proposals/0371-isolated-synchronous-deinit.md
    /// otherwise we wouldn't be able to log the tag in the deinit.
    deinit {
        ExtensionLogger.logMemory(with: tag)
        MXLog.info("\(tag) deinit")
    }
    
    override init() {
        appHooks = AppHooks()
        appHooks.setUp()
        
        // If the device is still locked then we can't write to the app group container and
        // the target configuration will fail. We could call exit(0) here, however with the
        // notification filtering entitlement that results in the notification being discarded
        // so we need to wait for the delegate method to be called and bail out there instead.
        if !DataProtectionManager.isDeviceLockedAfterReboot(containerURL: URL.appGroupContainerDirectory),
           Self.targetConfiguration == nil {
            Self.targetConfiguration = Target.nse.configure(logLevel: settings.logLevel,
                                                            traceLogPacks: settings.traceLogPacks,
                                                            sentryURL: nil,
                                                            rageshakeURL: settings.bugReportRageshakeURL,
                                                            appHooks: appHooks)
        }
        
        super.init()
    }
    
    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        Task { await handle(request, withContentHandler: contentHandler) }
    }
    
    private func handle(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) async {
        // If we skipped configuring the target it means we can't write to the app group, so we're unlikely to
        // be able to create a session (and even if we could, we would be missing the lightweightTokioRuntime).
        // Additionally APNs servers only store the most recent notification when the device is powered off.
        // So lets a) skip processing the notification and b) deliver a special "offline" notification as a workaround.
        guard Self.targetConfiguration != nil else {
            // MXLog isn't configured:
            // swiftlint:disable:next print_deprecation
            print("Device is locked after reboot.")
            Self.hasHandledFirstNotificationSinceBoot = true
            deliverReceivedWhileOfflineNotification(for: request)
            return contentHandler(.init())
        }
        
        // The APNs servers only store the most recent notification when delivery fails. So if this is the
        // first notification since the device booted, instead of delivering the content, we deliver a
        // special "offline" notification as a workaround to prompt the user to open the app.
        guard !isFirstNotificationSinceBoot() else {
            // Don't log until the app hooks have been run:
            // swiftlint:disable:next print_deprecation
            print("Device is unlocked and received the first notification since boot.")
            deliverReceivedWhileOfflineNotification(for: request)
            return contentHandler(.init())
        }
        
        guard let roomID = request.content.roomID else {
            // Don't log until the app hooks have been run:
            // swiftlint:disable:next print_deprecation
            print("Missing roomID, bailing out.")
            return contentHandler(request.content)
        }
        
        guard let eventID = request.content.eventID else {
            // Don't log until the app hooks have been run:
            // swiftlint:disable:next print_deprecation
            print("Missing eventID, bailing out.")
            return contentHandler(request.content)
        }
        
        guard let clientID = request.content.pusherNotificationClientIdentifier else {
            // Don't log until the app hooks have been run:
            // swiftlint:disable:next print_deprecation
            print("Missing clientID, bailing out.")
            return contentHandler(request.content)
        }
        
        guard let credentials = keychainController.restorationTokens().first(where: { $0.restorationToken.pusherNotificationClientIdentifier == clientID }) else {
            // Don't log until the app hooks have been run:
            // swiftlint:disable:next print_deprecation
            print("Credentials not found, bailing out.")
            return contentHandler(request.content)
        }
        
        let homeserverURL = credentials.restorationToken.session.homeserverUrl
        await appHooks.remoteSettingsHook.loadCache(forHomeserver: homeserverURL, applyingTo: settings)
        
        guard let mutableContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return contentHandler(request.content)
        }
        
        MXLog.info("\(tag) #########################################")
        
        ExtensionLogger.logMemory(with: tag)
        
        MXLog.info("\(tag) Received payload: \(request.content.userInfo)")
        
        do {
            let userSession = try await NSEUserSession(credentials: credentials,
                                                       roomID: roomID,
                                                       clientSessionDelegate: keychainController,
                                                       appHooks: appHooks,
                                                       appSettings: settings)
            
            notificationHandler = NotificationHandler(userSession: userSession,
                                                      settings: settings,
                                                      contentHandler: contentHandler,
                                                      notificationContent: mutableContent,
                                                      tag: tag)
            
            ExtensionLogger.logMemory(with: tag)
            MXLog.info("\(tag) Configured user session")
            
            await notificationHandler?.processEvent(eventID, roomID: roomID)
        } catch {
            MXLog.error("Failed creating user session with error: \(error)")
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        notificationHandler?.handleTimeExpiration()
    }
    
    // MARK: - Boot handling
    
    private let bootTimeKey = "lastKnownBootTime"
    
    /// Whether this is the first notification since the system booted and so may actually represent
    /// multiple notifications as the APNs server only queues a single push when deliveries fail.
    func isFirstNotificationSinceBoot() -> Bool {
        if Self.hasHandledFirstNotificationSinceBoot {
            // If we've already handled the first notification in this process there's no need to continue.
            return false
        }
        
        defer { Self.hasHandledFirstNotificationSinceBoot = true }
        
        guard let currentBootTime = systemBootTime() else {
            // There's not much we can do if the boot time is unknown, so we simply ignore this.
            return false
        }
        
        guard let userDefaults = UserDefaults(suiteName: InfoPlistReader.main.appGroupIdentifier),
              let lastKnownBootTime = userDefaults.object(forKey: bootTimeKey) as? TimeInterval else {
            // Assume a missing boot time indicates a fresh installation.
            return false
        }
        
        if abs(lastKnownBootTime - currentBootTime) < 1 {
            return false
        }
        
        // This is the first notification since boot, store the boot time.
        userDefaults.set(currentBootTime, forKey: bootTimeKey)
        return true
    }
    
    func systemBootTime() -> TimeInterval? {
        var bootTime = timeval()
        var size = MemoryLayout<timeval>.size
        var managementInformationBase: [Int32] = [CTL_KERN, KERN_BOOTTIME]
        
        guard sysctl(&managementInformationBase, 2, &bootTime, &size, nil, 0) == 0 else { return nil }
        
        return TimeInterval(bootTime.tv_sec) + TimeInterval(bootTime.tv_usec) / 1_000_000
    }
    
    /// Delivers a generic notification informing the user that they have one or more new messages.
    ///
    /// This method is designed to be called multiple times before unlock as it simply replaces any
    /// existing instance of the notification with a fresh copy (to ensure that the sound is still triggered).
    private func deliverReceivedWhileOfflineNotification(for originalRequest: UNNotificationRequest) {
        MXLog.info("Delivering the receivedWhileOfflineNotification.")
        
        let content = UNMutableNotificationContent()
        content.body = L10n.notificationReceivedWhileOfflineIos
        content.badge = originalRequest.content.unreadCount as NSNumber?
        content.sound = .init(named: .init("message.caf"))
        
        let request = UNNotificationRequest(identifier: Self.receivedWhileOfflineNotificationID, content: content, trigger: nil)
        UNUserNotificationCenter.current().add(request)
    }
    
    // MARK: - Logging
    
    private var tag: String {
        "[NSE][\(Unmanaged.passUnretained(self).toOpaque())][\(Unmanaged.passUnretained(Thread.current).toOpaque())][\(ProcessInfo.processInfo.processIdentifier)]"
    }
}
