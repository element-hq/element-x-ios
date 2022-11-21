//
// Copyright 2022 New Vector Ltd
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

class NotificationServiceProxy: NotificationServiceProxyProtocol {
//    private let service: NotificationServiceProtocol

    init(basePath: String,
         userId: String) {
//        service = NotificationService(basePath: basePath, userId: userId)
    }

    func notificationItem(roomId: String, eventId: String) async throws -> NotificationItemProxy? {
        nil
//        try await Task.dispatch(on: .global()) {
//            guard let item = try self.service.getNotificationItem(roomId: roomId, eventId: eventId) else {
//                return nil
//            }
//            return .init(notificationItem: item)
//        }
    }
}
