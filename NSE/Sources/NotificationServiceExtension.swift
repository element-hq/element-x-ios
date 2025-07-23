//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
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
    
    // We can make the whole NSE a MainActor after https://github.com/swiftlang/swift-evolution/blob/main/proposals/0371-isolated-synchronous-deinit.md
    // otherwise we wouldn't be able to log the tag in the deinit.
    deinit {
        ExtensionLogger.logMemory(with: tag)
        MXLog.info("\(tag) deinit")
    }
    
    override init() {
        appHooks = AppHooks()
        appHooks.setUp()
        
        if Self.targetConfiguration == nil {
            Self.targetConfiguration = Target.nse.configure(logLevel: settings.logLevel,
                                                            traceLogPacks: settings.traceLogPacks,
                                                            sentryURL: nil,
                                                            rageshakeURL: settings.bugReportRageshakeURL,
                                                            appHooks: appHooks)
        }
        
        super.init()
    }
    
    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        guard !DataProtectionManager.isDeviceLockedAfterReboot(containerURL: URL.appGroupContainerDirectory),
              let roomID = request.content.roomID,
              let eventID = request.content.eventID,
              let clientID = request.content.pusherNotificationClientIdentifier,
              let credentials = keychainController.restorationTokens().first(where: { $0.restorationToken.pusherNotificationClientIdentifier == clientID }) else {
            // We cannot process this notification, it might be due to one of these:
            // - Device rebooted and locked
            // - Not a Matrix notification
            // - User is not signed in
            // - NotificationID could not be resolved
            return contentHandler(request.content)
        }
        
        let homeserverURL = credentials.restorationToken.session.homeserverUrl
        appHooks.remoteSettingsHook.loadCache(forHomeserver: homeserverURL, applyingTo: settings)
        
        guard let mutableContent = request.content.mutableCopy() as? UNMutableNotificationContent else {
            return contentHandler(request.content)
        }
        
        MXLog.info("\(tag) #########################################")
        
        ExtensionLogger.logMemory(with: tag)
        
        MXLog.info("\(tag) Received payload: \(request.content.userInfo)")
        
        Task {
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
    }
    
    override func serviceExtensionTimeWillExpire() {
        notificationHandler?.handleTimeExpiration()
    }
    
    // MARK: - Private
    
    private var tag: String {
        "[NSE][\(Unmanaged.passUnretained(self).toOpaque())][\(Unmanaged.passUnretained(Thread.current).toOpaque())][\(ProcessInfo.processInfo.processIdentifier)]"
    }
}
