//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import UserNotifications

protocol NotificationItemProxyProtocol {
    var event: NotificationEvent? { get }
    
    var senderID: String { get }

    var roomID: String { get }

    var receiverID: String { get }

    var senderDisplayName: String? { get }

    var senderAvatarMediaSource: MediaSourceProxy? { get }

    var roomDisplayName: String { get }

    var roomAvatarMediaSource: MediaSourceProxy? { get }

    var roomJoinedMembers: Int { get }

    var isRoomDirect: Bool { get }

    var isNoisy: Bool { get }

    var hasMention: Bool { get }
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
