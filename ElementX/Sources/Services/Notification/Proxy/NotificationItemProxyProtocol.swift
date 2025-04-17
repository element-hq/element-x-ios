//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
    
    var isRoomPrivate: Bool { get }

    var isNoisy: Bool { get }

    var hasMention: Bool { get }
}

extension NotificationItemProxyProtocol {
    var isDM: Bool {
        isRoomDirect && roomJoinedMembers <= 2
    }
}
