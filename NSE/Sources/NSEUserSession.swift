//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

final class NSEUserSession {
    let sessionDirectories: SessionDirectories
    
    private let baseClient: Client
    private let notificationClient: NotificationClient
    private let userID: String
    private(set) lazy var mediaProvider: MediaProviderProtocol = MediaProvider(mediaLoader: MediaLoader(client: baseClient),
                                                                               imageCache: .onlyOnDisk,
                                                                               networkMonitor: nil)
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

    init(credentials: KeychainCredentials,
         roomID: String,
         clientSessionDelegate: ClientSessionDelegate,
         appHooks: AppHooks,
         appSettings: CommonSettingsProtocol) async throws {
        sessionDirectories = credentials.restorationToken.sessionDirectories
        userID = credentials.userID
        
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
            .sessionPaths(dataPath: credentials.restorationToken.sessionDirectories.dataPath,
                          cachePath: credentials.restorationToken.sessionDirectories.cachePath)
            .username(username: credentials.userID)
            .homeserverUrl(url: homeserverURL)
            .sessionPassphrase(passphrase: credentials.restorationToken.passphrase)
        
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

private class ClientDelegateWrapper: ClientDelegate {
    // MARK: - ClientDelegate

    func didReceiveAuthError(isSoftLogout: Bool) {
        MXLog.error("Received authentication error, the NSE can't handle this.")
    }
    
    func didRefreshTokens() {
        MXLog.info("Delegating session updates to the ClientSessionDelegate.")
    }
}
