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
import UserNotifications

protocol NotificationItemProxyProtocol {
    var event: NotificationEvent? { get }

    var eventID: String { get }

    var senderID: String { get }

    var roomID: String { get }

    var receiverID: String { get }

    var senderDisplayName: String? { get }

    var senderAvatarMediaSource: MediaSourceProxy? { get }

    var roomDisplayName: String { get }

    var roomCanonicalAlias: String? { get }

    var roomAvatarMediaSource: MediaSourceProxy? { get }

    var roomJoinedMembers: Int { get }

    var isRoomDirect: Bool { get }

    var isNoisy: Bool { get }
}

extension NotificationItemProxyProtocol {
    var isDM: Bool {
        isRoomDirect && roomJoinedMembers <= 2
    }
    
    var hasMedia: Bool {
        if (isDM && senderAvatarMediaSource != nil) ||
            (!isDM && roomAvatarMediaSource != nil) {
            return true
        }
        switch event {
        case .invite, .none:
            return false
        case .timeline(let event):
            switch try? event.eventType() {
            case .state, .none:
                return false
            case let .messageLike(content):
                switch content {
                case let .roomMessage(messageType, _):
                    switch messageType {
                    case .image, .video, .audio:
                        return true
                    default:
                        return false
                    }
                default:
                    return false
                }
            }
        }
    }
}
