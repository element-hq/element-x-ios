//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import CallKit
import Intents
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
//
// We keep a global `environment` singleton to ensure that our app context,
// database, logging, etc. are only ever setup once per *process*

private let settings: CommonSettingsProtocol = AppSettings()
private let notificationContentBuilder = NotificationContentBuilder(messageEventStringBuilder: RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(mentionBuilder: PlainMentionBuilder()), destination: .notification),
                                                                    settings: settings)
private let keychainController = KeychainController(service: .sessions,
                                                    accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)

class NotificationServiceExtension: UNNotificationServiceExtension {
    private var handler: ((UNNotificationContent) -> Void)?
    private var modifiedContent: UNMutableNotificationContent?
    
    private let appHooks = AppHooks()
    
    // Used to create one single UserSession across process/instances/runs
    private static let serialQueue = DispatchQueue(label: "io.element.elementx.nse")
    
    // Temporary. We need to make sure the NSE and the main app pass in the same value.
    // The NSE has a tendency of staying alive for longer so use this to manually kill it
    // when the feature flag doesn't match.
    private static var eventCacheEnabled = false
    
    private static var userSession: NSEUserSession? {
        didSet {
            eventCacheEnabled = settings.eventCacheEnabled
        }
    }
    
    deinit {
        cleanUp()
        ExtensionLogger.logMemory(with: tag)
        MXLog.info("\(tag) deinit")
    }
    
    override func didReceive(_ request: UNNotificationRequest,
                             withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        guard !DataProtectionManager.isDeviceLockedAfterReboot(containerURL: URL.appGroupContainerDirectory),
              let roomID = request.roomID,
              let eventID = request.eventID,
              let clientID = request.pusherNotificationClientIdentifier,
              let credentials = keychainController.restorationTokens().first(where: { $0.restorationToken.pusherNotificationClientIdentifier == clientID }) else {
            // We cannot process this notification, it might be due to one of these:
            // - Device rebooted and locked
            // - Not a Matrix notification
            // - User is not signed in
            // - NotificationID could not be resolved
            return contentHandler(request.content)
        }

        handler = contentHandler
        modifiedContent = request.content.mutableCopy() as? UNMutableNotificationContent

        ExtensionLogger.configure(currentTarget: "nse", logLevel: settings.logLevel)

        MXLog.info("\(tag) #########################################")
        ExtensionLogger.logMemory(with: tag)
        MXLog.info("\(tag) Payload came: \(request.content.userInfo)")
        
        Self.serialQueue.sync {
            // If the session directories have changed, the user has logged out and back in (even if they entered the same user ID).
            // We can't do this comparison with the access token of the existing session here due to token refresh when using OIDC.
            if Self.userSession == nil || Self.userSession?.sessionDirectories != credentials.restorationToken.sessionDirectories {
                // This function might be run concurrently and from different processes
                // It's imperative that we create **at most** one UserSession/Client per process
                Task.synchronous { [appHooks] in
                    do {
                        Self.userSession = try await NSEUserSession(credentials: credentials,
                                                                    clientSessionDelegate: keychainController,
                                                                    appHooks: appHooks,
                                                                    appSettings: settings)
                    } catch {
                        MXLog.error("Failed creating user session with error: \(error)")
                    }
                }
            }
            
            if Self.userSession == nil {
                return discard(unreadCount: request.unreadCount)
            }
        }
        
        guard Self.eventCacheEnabled == settings.eventCacheEnabled else {
            MXLog.error("Found missmatch `eventCacheEnabled` feature flag missmatch, restarting the NSE.")
            exit(0)
        }

        Task {
            await run(with: credentials,
                      roomID: roomID,
                      eventID: eventID,
                      unreadCount: request.unreadCount)
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        MXLog.warning("\(tag) serviceExtensionTimeWillExpire")
        notify(unreadCount: nil)
    }
    
    // MARK: - Private

    private func run(with credentials: KeychainCredentials,
                     roomID: String,
                     eventID: String,
                     unreadCount: Int?) async {
        MXLog.info("\(tag) run with roomId: \(roomID), eventId: \(eventID)")
        
        guard let userSession = Self.userSession else {
            MXLog.error("Invalid NSE User Session, discarding.")
            return discard(unreadCount: unreadCount)
        }

        do {
            guard let itemProxy = await userSession.notificationItemProxy(roomID: roomID, eventID: eventID) else {
                MXLog.info("\(tag) no notification for the event, discard")
                return discard(unreadCount: unreadCount)
            }
                  
            switch await preprocessNotification(itemProxy) {
            case .processedShouldDiscard, .unsupportedShouldDiscard:
                return discard(unreadCount: unreadCount)
            case .shouldDisplay:
                break
            }
            
            // After the first processing, update the modified content
            modifiedContent = try await notificationContentBuilder.content(for: itemProxy, mediaProvider: nil)
            
            guard itemProxy.hasMedia else {
                MXLog.info("\(tag) no media needed")

                // We've processed the item and no media operations needed, so no need to go further
                return notify(unreadCount: unreadCount)
            }

            MXLog.info("\(tag) process with media")

            // There is some media to load, process it again
            if let latestContent = try? await notificationContentBuilder.content(for: itemProxy, mediaProvider: userSession.mediaProvider) {
                // Processing finished, hopefully with some media
                modifiedContent = latestContent
            }
            // We still notify, but without the media attachment if it fails to load
            
            return notify(unreadCount: unreadCount)
        } catch {
            MXLog.error("NSE run error: \(error)")
            return discard(unreadCount: unreadCount)
        }
    }
    
    private func notify(unreadCount: Int?) {
        MXLog.info("\(tag) notify")

        guard let modifiedContent else {
            MXLog.info("\(tag) notify: no modified content")
            return discard(unreadCount: unreadCount)
        }
        
        if let unreadCount {
            modifiedContent.badge = NSNumber(value: unreadCount)
        }

        handler?(modifiedContent)
        cleanUp()
    }

    private func discard(unreadCount: Int?) {
        MXLog.info("\(tag) discard")
        
        let content = UNMutableNotificationContent()
        
        if let unreadCount {
            content.badge = NSNumber(value: unreadCount)
        }

        handler?(content)
        cleanUp()
    }

    private var tag: String {
        "[NSE][\(Unmanaged.passUnretained(self).toOpaque())][\(Unmanaged.passUnretained(Thread.current).toOpaque())][\(ProcessInfo.processInfo.processIdentifier)]"
    }

    private func cleanUp() {
        handler = nil
        modifiedContent = nil
    }
    
    private func preprocessNotification(_ itemProxy: NotificationItemProxyProtocol) async -> NotificationProcessingResult {
        guard case let .timeline(event) = itemProxy.event else {
            return .shouldDisplay
        }
        
        switch try? event.eventType() {
        case .messageLike(let content):
            switch content {
            case .poll,
                 .roomEncrypted,
                 .sticker:
                return .shouldDisplay
            case .roomMessage(let messageType, _):
                switch messageType {
                case .emote, .image, .audio, .video, .file, .notice, .text, .location:
                    return .shouldDisplay
                case .other:
                    return .unsupportedShouldDiscard
                }
            case .roomRedaction(let redactedEventID, _):
                guard let redactedEventID else {
                    MXLog.error("Unable to handle redact notification due to missing event ID.")
                    return .processedShouldDiscard
                }
                
                let deliveredNotifications = await UNUserNotificationCenter.current().deliveredNotifications()
                
                if let targetNotification = deliveredNotifications.first(where: { $0.request.content.eventID == redactedEventID }) {
                    UNUserNotificationCenter.current().removeDeliveredNotifications(withIdentifiers: [targetNotification.request.identifier])
                }
                
                return .processedShouldDiscard
            case .callNotify(let notifyType):
                return await handleCallNotification(notifyType: notifyType,
                                                    timestamp: event.timestamp(),
                                                    roomID: itemProxy.roomID,
                                                    roomDisplayName: itemProxy.roomDisplayName)
            case .callAnswer,
                 .callInvite,
                 .callHangup,
                 .callCandidates,
                 .keyVerificationReady,
                 .keyVerificationStart,
                 .keyVerificationCancel,
                 .keyVerificationAccept,
                 .keyVerificationKey,
                 .keyVerificationMac,
                 .keyVerificationDone,
                 .reactionContent:
                return .unsupportedShouldDiscard
            }
        case .state:
            return .unsupportedShouldDiscard
        case .none:
            return .unsupportedShouldDiscard
        }
    }
    
    /// Handle incoming call notifications.
    /// - Returns: A boolean indicating whether the notification was handled and should now be discarded.
    private func handleCallNotification(notifyType: NotifyType,
                                        timestamp: Timestamp,
                                        roomID: String,
                                        roomDisplayName: String) async -> NotificationProcessingResult {
        // Handle incoming VoIP calls, show the native OS call screen
        // https://developer.apple.com/documentation/callkit/sending-end-to-end-encrypted-voip-calls
        //
        // The way this works is the following:
        // - the NSE receives the notification and decrypts it
        // - checks if it's still time relevant (max 10 seconds old) and whether it should ring
        // - otherwise it goes on to show it as a normal notification
        // - if it should ring then it discards the notification but invokes `reportNewIncomingVoIPPushPayload`
        // so that the main app can handle it
        // - the main app picks this up in `PKPushRegistry.didReceiveIncomingPushWith` and
        // `CXProvider.reportNewIncomingCall` to show the system UI and handle actions on it.
        // N.B. this flow works properly only when background processing capabilities are enabled
        guard notifyType == .ring else {
            MXLog.info("Non-ringing call notification, handling as push notification")
            return .shouldDisplay
        }
        
        let timestamp = Date(timeIntervalSince1970: TimeInterval(timestamp / 1000))
        guard abs(timestamp.timeIntervalSinceNow) < ElementCallServiceNotificationDiscardDelta else {
            MXLog.info("Call notification is too old, handling as push notification")
            return .shouldDisplay
        }
        
        let payload = [ElementCallServiceNotificationKey.roomID.rawValue: roomID,
                       ElementCallServiceNotificationKey.roomDisplayName.rawValue: roomDisplayName]
        
        do {
            try await CXProvider.reportNewIncomingVoIPPushPayload(payload)
            MXLog.info("Call notification delegated to CallKit")
        } catch {
            MXLog.error("Failed reporting voip call with error: \(error). Handling as push notification")
            return .shouldDisplay
        }
        
        return .processedShouldDiscard
    }
    
    private enum NotificationProcessingResult {
        case shouldDisplay
        case processedShouldDiscard
        case unsupportedShouldDiscard
    }
}

// https://stackoverflow.com/a/77300959/730924
private extension Task where Failure == Error {
    /// Performs an async task in a sync context.
    ///
    /// - Note: This function blocks the thread until the given operation is finished. The caller is responsible for managing multithreading.
    static func synchronous(priority: TaskPriority? = nil, operation: @escaping @Sendable () async throws -> Success) {
        let semaphore = DispatchSemaphore(value: 0)

        Task(priority: priority) {
            defer { semaphore.signal() }
            return try await operation()
        }

        semaphore.wait()
    }
}
