//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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

    init(credentials: KeychainCredentials, clientSessionDelegate: ClientSessionDelegate, appHooks: AppHooks, appSettings: CommonSettingsProtocol) async throws {
        sessionDirectories = credentials.restorationToken.sessionDirectories
        
        userID = credentials.userID
        if credentials.restorationToken.passphrase != nil {
            MXLog.info("Restoring client with encrypted store.")
        }
        
        let homeserverURL = credentials.restorationToken.session.homeserverUrl
        let clientBuilder = ClientBuilder
            .baseBuilder(setupEncryption: false,
                         httpProxy: URL(string: homeserverURL)?.globalProxy,
                         slidingSync: .restored,
                         sessionDelegate: clientSessionDelegate,
                         appHooks: appHooks,
                         invisibleCryptoEnabled: appSettings.invisibleCryptoEnabled)
            .sessionPaths(dataPath: credentials.restorationToken.sessionDirectories.dataPath,
                          cachePath: credentials.restorationToken.sessionDirectories.cachePath)
            .username(username: credentials.userID)
            .homeserverUrl(url: homeserverURL)
            .passphrase(passphrase: credentials.restorationToken.passphrase)
        
        baseClient = try await clientBuilder.build()
        delegateHandle = baseClient.setDelegate(delegate: ClientDelegateWrapper())
        try await baseClient.restoreSession(session: credentials.restorationToken.session)
        
        notificationClient = try await baseClient.notificationClient(processSetup: .multipleProcesses)
    }
    
    func notificationItemProxy(roomID: String, eventID: String) async -> NotificationItemProxyProtocol? {
        do {
            let notification = try await notificationClient.getNotification(roomId: roomID, eventId: eventID)
                
            guard let notification else {
                return nil
            }
            return NotificationItemProxy(notificationItem: notification,
                                         eventID: eventID,
                                         receiverID: userID,
                                         roomID: roomID)
        } catch {
            MXLog.error("NSE: Could not get notification's content creating an empty notification instead, error: \(error)")
            return EmptyNotificationItemProxy(eventID: eventID, roomID: roomID, receiverID: userID)
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
