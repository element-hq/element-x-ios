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

private let settings: CommonSettingsProtocol = AppSettings()

private let keychainController = KeychainController(service: .sessions,
                                                    accessGroup: InfoPlistReader.main.keychainAccessGroupIdentifier)

private let eventStringBuilder = RoomMessageEventStringBuilder(attributedStringBuilder: AttributedStringBuilder(mentionBuilder: PlainMentionBuilder()),
                                                               destination: .notification)

private let notificationContentBuilder = NotificationContentBuilder(messageEventStringBuilder: eventStringBuilder,
                                                                    settings: settings)

class NotificationServiceExtension: UNNotificationServiceExtension {
    private var handler: ((UNNotificationContent) -> Void)?
    private var modifiedContent: UNMutableNotificationContent?
    
    private let appHooks = AppHooks()
            
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
        
        Target.nse.configure(logLevel: settings.logLevel, traceLogPacks: settings.traceLogPacks)

        handler = contentHandler
        modifiedContent = request.content.mutableCopy() as? UNMutableNotificationContent
        
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
                
                ExtensionLogger.logMemory(with: tag)
                MXLog.info("\(tag) Configured user session")
                
                await processEvent(eventID,
                                   roomID: roomID,
                                   unreadCount: request.unreadCount,
                                   userSession: userSession)
            } catch {
                MXLog.error("Failed creating user session with error: \(error)")
            }
        }
    }
    
    override func serviceExtensionTimeWillExpire() {
        // Called just before the extension will be terminated by the system.
        // Use this as an opportunity to deliver your "best attempt" at modified content, otherwise the original push payload will be used.
        MXLog.warning("\(tag) Extension time will expire")
        notify(unreadCount: nil)
    }
    
    // MARK: - Private

    private func processEvent(_ eventID: String,
                              roomID: String,
                              unreadCount: Int?,
                              userSession: NSEUserSession) async {
        MXLog.info("\(tag) Processing event: \(eventID) in room: \(roomID)")
        
        do {
            guard let itemProxy = await userSession.notificationItemProxy(roomID: roomID, eventID: eventID) else {
                MXLog.error("\(tag) Failed retrieving notification item")
                return discard(unreadCount: unreadCount)
            }
                  
            switch await preprocessNotification(itemProxy) {
            case .processedShouldDiscard, .unsupportedShouldDiscard:
                return discard(unreadCount: unreadCount)
            case .shouldDisplay:
                break
            }
            
            modifiedContent = try await notificationContentBuilder.content(for: itemProxy, mediaProvider: nil)
            
            guard itemProxy.hasMedia else {
                MXLog.info("\(tag) Notification item doesn't contain media")
                return notify(unreadCount: unreadCount)
            }

            MXLog.info("\(tag) Processing media")
            if let latestContent = try? await notificationContentBuilder.content(for: itemProxy, mediaProvider: userSession.mediaProvider) {
                modifiedContent = latestContent
            } else {
                MXLog.error("\(tag) Failed processing notification media")
            }
            
            return notify(unreadCount: unreadCount)
        } catch {
            MXLog.error("Failed processing with error: \(error)")
            return discard(unreadCount: unreadCount)
        }
    }
    
    private func notify(unreadCount: Int?) {
        guard let modifiedContent else {
            MXLog.error("\(tag) Notification modified content invalid")
            return discard(unreadCount: unreadCount)
        }
        
        MXLog.info("\(tag) Displaying notification")
        
        if let unreadCount {
            modifiedContent.badge = NSNumber(value: unreadCount)
        }

        handler?(modifiedContent)
        cleanUp()
    }

    private func discard(unreadCount: Int?) {
        MXLog.info("\(tag) Discarding notification")
        
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
                    MXLog.error("Unable to handle redact notification due to missing event ID")
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
