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
    private let client: ClientProtocol
    private var encryptionSyncService: EncryptionSync!
    private(set) lazy var mediaProvider: MediaProviderProtocol = MediaProvider(mediaLoader: MediaLoader(client: client),
                                                                               imageCache: .onlyOnDisk,
                                                                               backgroundTaskService: nil)

    init(credentials: KeychainCredentials) throws {
        let builder = ClientBuilder()
            .basePath(path: URL.sessionsBaseDirectory.path)
            .username(username: credentials.userID)

        client = try builder.build()
        try client.restoreSession(session: credentials.restorationToken.session)

        let listener = EncryptionSyncListenerProxy {
            MXLog.info("NSE: Encryption sync terminated for user: \(credentials.userID)")
        }
        encryptionSyncService = try client.notificationEncryptionSync(id: "NSE", listener: listener, numIters: 2)
    }

    func notificationItemProxy(roomID: String, eventID: String) async throws -> NotificationItemProxyProtocol? {
        let userID = try client.userId()
        return await Task.dispatch(on: .global()) {
            do {
                guard let notification = try self.client.getNotificationItem(roomId: roomID, eventId: eventID) else {
                    return nil
                }
                return NotificationItemProxy(notificationItem: notification, receiverID: userID)
            } catch {
                MXLog.error("NSE: Could not get notification's content creating an empty notification instead, error: \(error)")
                return EmptyNotificationItemProxy(eventID: eventID, roomID: roomID, receiverID: userID)
            }
        }
    }

    deinit {
        encryptionSyncService?.stop()
    }
}
