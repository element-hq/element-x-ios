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
    private static var targetConfiguration: Target.ConfigurationResult?
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
        // If we skipped configuring the target it means we can't write to the app group, so we're unlikely
        // to be able to create a session (and even if we could, we would be missing the lightweightTokioRuntime),
        // so instead lets deliver the default generic notification and avoid attempting to process the notification.
        guard Self.targetConfiguration != nil else {
            // MXLog isn't configured
            // swiftlint:disable:next print_deprecation
            print("Device is locked after reboot, delivering the unmodified notification.")
            return contentHandler(request.content)
        }
        
        guard let roomID = request.content.roomID else {
            MXLog.error("Invalid roomID, bailing out: \(request.content)")
            return contentHandler(request.content)
        }
        
        guard let eventID = request.content.eventID else {
            MXLog.error("Invalid eventID, bailing out: \(request.content)")
            return contentHandler(request.content)
        }
        
        guard let clientID = request.content.pusherNotificationClientIdentifier else {
            MXLog.error("Invalid eventID, bailing out: \(request.content)")
            return contentHandler(request.content)
        }
        
        guard let credentials = keychainController.restorationTokens().first(where: { $0.restorationToken.pusherNotificationClientIdentifier == clientID }) else {
            MXLog.error("Invalid credentials, bailing out: \(request.content)")
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
    
    // MARK: - Private
    
    private var tag: String {
        "[NSE][\(Unmanaged.passUnretained(self).toOpaque())][\(Unmanaged.passUnretained(Thread.current).toOpaque())][\(ProcessInfo.processInfo.processIdentifier)]"
    }
}
