//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import MatrixRustSDK

final class NSEUserSession {
    private let baseClient: Client
    private let notificationClient: NotificationClient
    private let userID: String
    private(set) lazy var mediaProvider: MediaProviderProtocol = MediaProvider(mediaLoader: MediaLoader(client: baseClient),
                                                                               imageCache: .onlyOnDisk,
                                                                               backgroundTaskService: nil)

    init(credentials: KeychainCredentials, isEncryptionSyncEnabled: Bool) throws {
        userID = credentials.userID
        baseClient = try ClientBuilder()
            .basePath(path: URL.sessionsBaseDirectory.path)
            .username(username: credentials.userID)
            .build()

        try baseClient.restoreSession(session: credentials.restorationToken.session)

        notificationClient = baseClient
            .notificationClient()
            .retryDecryption(withCrossProcessLock: isEncryptionSyncEnabled)
            .finish()
    }

    func notificationItemProxy(roomID: String, eventID: String) async -> NotificationItemProxyProtocol? {
        await Task.dispatch(on: .global()) {
            do {
                guard let notification = try self.notificationClient.getNotification(roomId: roomID, eventId: eventID) else {
                    return nil
                }
                return NotificationItemProxy(notificationItem: notification, receiverID: self.userID, roomID: roomID)
            } catch {
                MXLog.error("NSE: Could not get notification's content creating an empty notification instead, error: \(error)")
                return EmptyNotificationItemProxy(eventID: eventID, roomID: roomID, receiverID: self.userID)
            }
        }
    }
}
