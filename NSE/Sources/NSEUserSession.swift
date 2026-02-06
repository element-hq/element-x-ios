//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

// sourcery: AutoMockable
protocol NSEUserSessionProtocol {
    var inviteAvatarsVisibility: InviteAvatars { get async }
    var mediaPreviewVisibility: MediaPreviews { get async }
    var threadsEnabled: Bool { get }
    
    func notificationItemProxy(roomID: String, eventID: String) async -> NotificationItemProxyProtocol?
    func roomForIdentifier(_ roomID: String) -> Room?
}

final class NSEUserSession: NSEUserSessionProtocol {
    private let sessionDirectories: SessionDirectories
    private let appSettings: CommonSettingsProtocol
    private let baseClient: Client
    private let notificationClient: NotificationClient
    private let userID: String
    private(set) lazy var mediaProvider: MediaProviderProtocol = MediaProvider(mediaLoader: MediaLoader(client: baseClient),
                                                                               imageCache: .onlyOnDisk,
                                                                               homeserverReachabilityPublisher: nil)
    private let delegateHandle: TaskHandle?
    
    var mediaPreviewVisibility: MediaPreviews {
        get async {
            do {
                return try await baseClient.getMediaPreviewDisplayPolicy() ?? .on
            } catch {
                MXLog.error("Failed to get media preview visibility, defaulting to on. Error: \(error)")
                return .on
            }
        }
    }
    
    var inviteAvatarsVisibility: InviteAvatars {
        get async {
            do {
                return try await baseClient.getInviteAvatarsDisplayPolicy() ?? .on
            } catch {
                MXLog.error("Failed to get invite avatars visibility, defaulting to on. Error: \(error)")
                return .on
            }
        }
    }
    
    var threadsEnabled: Bool {
        appSettings.threadsEnabled
    }

    init(credentials: KeychainCredentials,
         roomID: String,
         clientSessionDelegate: ClientSessionDelegate,
         appHooks: AppHooks,
         appSettings: CommonSettingsProtocol) async throws {
        sessionDirectories = credentials.restorationToken.sessionDirectories
        userID = credentials.userID
        self.appSettings = appSettings
        
        let homeserverURL = credentials.restorationToken.session.homeserverUrl
        let clientBuilder = ClientBuilder
            .baseBuilder(setupEncryption: false,
                         httpProxy: URL(string: homeserverURL)?.globalProxy,
                         slidingSync: .restored,
                         sessionDelegate: clientSessionDelegate,
                         appHooks: appHooks,
                         enableOnlySignedDeviceIsolationMode: appSettings.enableOnlySignedDeviceIsolationMode,
                         enableKeyShareOnInvite: appSettings.enableKeyShareOnInvite,
                         requestTimeout: 15000,
                         maxRequestRetryTime: 5000,
                         threadsEnabled: appSettings.threadsEnabled)
            .systemIsMemoryConstrained()
            .sqliteStore(config: .init(dataPath: credentials.restorationToken.sessionDirectories.dataPath,
                                       cachePath: credentials.restorationToken.sessionDirectories.cachePath)
                    .passphrase(passphrase: credentials.restorationToken.passphrase))
            .username(username: credentials.userID)
            .homeserverUrl(url: homeserverURL)
        
        baseClient = try await clientBuilder.build()
        delegateHandle = try baseClient.setDelegate(delegate: ClientDelegateWrapper())
        
        try await baseClient.restoreSessionWith(session: credentials.restorationToken.session,
                                                roomLoadSettings: .one(roomId: roomID))
        
        notificationClient = try await baseClient.notificationClient(processSetup: .multipleProcesses)
    }
    
    func notificationItemProxy(roomID: String, eventID: String) async -> NotificationItemProxyProtocol? {
        do {
            let notificationStatus = try await notificationClient.getNotification(roomId: roomID, eventId: eventID)
                
            switch notificationStatus {
            case .event(let notification):
                return NotificationItemProxy(notificationItem: notification,
                                             eventID: eventID,
                                             receiverID: userID,
                                             roomID: roomID)
            case .eventNotFound:
                MXLog.error("Notification event not found - roomID: \(roomID) eventID: \(eventID)")
                return nil
            case .eventFilteredOut:
                MXLog.warning("Notification event filtered out - roomID: \(roomID) eventID: \(eventID)")
                return nil
            }
        } catch {
            MXLog.error("Could not get notification's content creating an empty notification instead, error: \(error)")
            return EmptyNotificationItemProxy(eventID: eventID, roomID: roomID, receiverID: userID)
        }
    }
    
    func roomForIdentifier(_ roomID: String) -> Room? {
        do {
            return try notificationClient.getRoom(roomId: roomID)
        } catch {
            MXLog.error("Failed retrieving room with error: \(error)")
            return nil
        }
    }
    
    deinit {
        delegateHandle?.cancel()
    }
}

private final class ClientDelegateWrapper: ClientDelegate {
    // MARK: - ClientDelegate

    func didReceiveAuthError(isSoftLogout: Bool) {
        MXLog.error("Received authentication error, the NSE can't handle this.")
    }
    
    func didRefreshTokens() {
        MXLog.info("Delegating session updates to the ClientSessionDelegate.")
    }
    
    func onBackgroundTaskErrorReport(taskName: String, error: MatrixRustSDK.BackgroundTaskFailureReason) {
        switch error {
        case .panic(let message, let backtrace):
            MXLog.error("Received background task panic: \(message ?? "Missing message")\nBacktrace:\n\(backtrace ?? "Missing backtrace")")
        case .error(let error):
            MXLog.error("Received background task error: \(error)")
        case .earlyTermination:
            MXLog.error("Received background task early termination")
        }
    }
}
