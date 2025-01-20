//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

final class RoomPreviewProxy: RoomPreviewProxyProtocol {
    private let roomPreview: RoomPreview
    
    let info: RoomPreviewInfoProxy
    
    init(roomPreview: RoomPreview) throws {
        self.roomPreview = roomPreview
        info = try .init(roomPreviewInfo: roomPreview.info())
    }
    
    var ownMembershipDetails: RoomMembershipDetailsProxyProtocol? {
        get async {
            guard let details = await roomPreview.ownMembershipDetails() else {
                return nil
            }
            
            var senderRoomMember: RoomMemberProxy?
            if let member = details.senderRoomMember {
                senderRoomMember = .init(member: member)
            }
            
            return RoomMembershipDetailsProxy(ownRoomMember: RoomMemberProxy(member: details.ownRoomMember),
                                              senderRoomMember: senderRoomMember)
        }
    }
}
