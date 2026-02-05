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
    private static let firstNotificationThreshold: TimeInterval = 15 * 60
    
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
            
            if Self.hasHandledFirstNotificationSinceBoot {
                return contentHandler(request.content)
            } else {
                Self.hasHandledFirstNotificationSinceBoot = true
                deliverReceivedWhileOfflineNotification(for: request)
                return contentHandler(.init())
            }
        }
        
        guard !shouldDeliverReceivedWhileOfflineNotification() else {
            // Don't log until the app hooks have been run:
            // swiftlint:disable:next print_deprecation
            print("Device is unlocked but may have missed notifications while offline.")
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
    
    /// The APNs servers only store the most recent notification when delivery fails. So when the user first boots
    /// their phone we need to use some approximations to decide whether or not the first notification may potentially
    /// represent more than one message. When that appears possible we replace the notification's content with the special
    /// "received while offline" notification as a more prominent prompt for to the user to open the app and check all their chats.
    ///
    /// Note that this only handles the first-boot case. When the SDK is able to compute the unread count, we should start to use the NSE,
    /// remote-notifications (content-available) and background app refreshes to fetch and deliver our notifications as a more robust solution.
    func shouldDeliverReceivedWhileOfflineNotification() -> Bool {
        if Self.hasHandledFirstNotificationSinceBoot {
            // If we've already handled the first notification in this process there's no need to continue.
            return false
        }
        
        Self.hasHandledFirstNotificationSinceBoot = true
        
        guard let currentBootTime = systemBootTime() else {
            // There's not much we can do if the boot time is unknown, so don't show the offline notification.
            return false
        }
        
        guard let lastKnownBootTime = settings.lastNotificationBootTime else {
            // Assume a missing boot time indicates a fresh installation…
            // So store the current boot time but let the notification through.
            settings.lastNotificationBootTime = currentBootTime
            return false
        }
        
        if abs(lastKnownBootTime - currentBootTime) < 1 {
            return false
        }
        
        // This is the first notification since boot, store the boot time.
        settings.lastNotificationBootTime = currentBootTime
        
        // At this point it becomes a trade-off. Once the device has been powered on for a long enough amount
        // of time it is a reasonable assumption that the device has now connected to a network and that any
        // notification is actually new rather than having been sent whilst the device was powered off.
        //
        // Note: We could actually solve this by having Sygnal add a timestamp to the notification payload 🤔
        if Date.now.timeIntervalSince(Date(timeIntervalSince1970: currentBootTime)) > Self.firstNotificationThreshold {
            return false
        } else {
            return true
        }
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
    /// Note: it is safe to call this method multiple times as it simply replaces any existing instance of the notification
    /// with a fresh copy, meaning it won't queue multiple copies but will still re-play the notification sound.
    private func deliverReceivedWhileOfflineNotification(for originalRequest: UNNotificationRequest) {
        // Don't log until the app hooks have been run:
        // swiftlint:disable:next print_deprecation
        print("Delivering the 'received while offline' notification.")
        
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
