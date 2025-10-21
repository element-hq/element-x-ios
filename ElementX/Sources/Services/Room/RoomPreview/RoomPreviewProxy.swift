//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

final class RoomPreviewProxy: RoomPreviewProxyProtocol {
    private let roomPreview: RoomPreview
    
    let info: RoomPreviewInfoProxy
    
    init(roomPreview: RoomPreview) {
        self.roomPreview = roomPreview
        info = .init(roomPreviewInfo: roomPreview.info())
    }
    
    var ownMembershipDetails: RoomMembershipDetailsProxyProtocol? {
        get async {
            guard let details = await roomPreview.ownMembershipDetails() else {
                return nil
            }
            
            var senderRoomMember: RoomMemberProxy?
            if let member = details.senderInfo {
                senderRoomMember = .init(member: member)
            }
            
            return RoomMembershipDetailsProxy(ownRoomMember: RoomMemberProxy(member: details.roomMember),
                                              senderRoomMember: senderRoomMember)
        }
    }
}
