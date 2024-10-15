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
    private let zeroUsers: [ZMatrixUser]

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
                         enableOnlySignedDeviceIsolationMode: appSettings.enableOnlySignedDeviceIsolationMode)
            .sessionPaths(dataPath: credentials.restorationToken.sessionDirectories.dataPath,
                          cachePath: credentials.restorationToken.sessionDirectories.cachePath)
            .username(username: credentials.userID)
            .homeserverUrl(url: homeserverURL)
            .passphrase(passphrase: credentials.restorationToken.passphrase)
        
        baseClient = try await clientBuilder.build()
        delegateHandle = baseClient.setDelegate(delegate: ClientDelegateWrapper())
        try await baseClient.restoreSession(session: credentials.restorationToken.session)
        
        notificationClient = try await baseClient.notificationClient(processSetup: .multipleProcesses)
        
        zeroUsers = appSettings.zeroMatrixUsers ?? []
    }
    
    func notificationItemProxy(roomID: String, eventID: String) async -> NotificationItemProxyProtocol? {
        do {
            let notification = try await notificationClient.getNotification(roomId: roomID, eventId: eventID)
                
            guard let notification else {
                return nil
            }
            
            // Custom data required to set data as per zero
            let senderDisplayInfo = getNotificationSenderDisplayInfo(notification: notification)
            
            return NotificationItemProxy(notificationItem: notification,
                                         eventID: eventID,
                                         receiverID: userID,
                                         roomID: roomID,
                                         notificationSenderDisplayInfo: senderDisplayInfo)
        } catch {
            MXLog.error("NSE: Could not get notification's content creating an empty notification instead, error: \(error)")
            return EmptyNotificationItemProxy(eventID: eventID, roomID: roomID, receiverID: userID)
        }
    }
    
    private func getNotificationSenderDisplayInfo(notification: NotificationItem) -> NotificationSenderDisplayInfo? {
        var senderID: String {
            switch notification.event {
            case .timeline(let event):
                return event.senderId()
            case .invite(let senderID):
                return senderID
            }
        }
        let zeroUser = zeroUsers.first(where: { $0.matrixId == senderID })
        let senderDisplayInfo = (zeroUser != nil) ? NotificationSenderDisplayInfo(
            name: zeroUser?.displayName ?? senderID,
            avatarUrl: notification.senderInfo.avatarUrl
        ) : nil
        return senderDisplayInfo
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
