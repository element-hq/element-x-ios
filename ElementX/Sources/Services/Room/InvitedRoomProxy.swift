//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import UIKit

class InvitedRoomProxy: InvitedRoomProxyProtocol {
    private let roomListItem: RoomListItemProtocol
    
    private var roomPreview: RoomPreview?
    private var invitedRoom: Room?
    
    let info: BaseRoomInfoProxyProtocol
    let ownUserID: String
    let inviter: RoomMemberProxyProtocol?
    
    // A room identifier is constant and lazy stops it from being fetched
    // multiple times over FFI
    lazy var id: String = info.id
        
    init(roomListItem: RoomListItemProtocol, ownUserID: String) async throws {
        self.roomListItem = roomListItem
        self.ownUserID = ownUserID
        
        // The room summary API might not be available on all the homeservers.
        // Try to resolve it with what info we already have which also happens to be faster.
        do {
            let roomPreview = try await roomListItem.previewRoom(via: [])
            self.roomPreview = roomPreview
            
            info = try RoomPreviewInfoProxy(roomPreviewInfo: roomPreview.info())
            inviter = await roomPreview.inviter().map(RoomMemberProxy.init)
        } catch {
            MXLog.error("Room preview fetching failed, fallback to known information.")
            let invitedRoom = try roomListItem.invitedRoom()
            
            self.invitedRoom = invitedRoom
            
            inviter = await invitedRoom.inviter().map(RoomMemberProxy.init)
            info = try await RoomInfoProxy(roomInfo: invitedRoom.roomInfo())
        }
    }
    
    func rejectInvitation() async -> Result<Void, RoomProxyError> {
        do {
            if let invitedRoom {
                return try await .success(invitedRoom.leave())
            } else if let roomPreview {
                return try await .success(roomPreview.leave())
            } else {
                fatalError("Invalid InvitedRoomProxy state, missing both `invitedRoom` and `roomPreview`")
            }
        } catch {
            MXLog.error("Failed rejecting invitiation with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
