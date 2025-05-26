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
    private let room: Room
    
    lazy var id: String = room.id()
    lazy var ownUserID: String = room.ownUserId()
    
    let info: BaseRoomInfoProxyProtocol
    let inviter: RoomMemberProxyProtocol?
            
    init(room: Room) async throws {
        self.room = room
        
        info = try await RoomInfoProxy(roomInfo: room.roomInfo())
        
        inviter = try? await room.inviter().map(RoomMemberProxy.init)
    }
    
    func rejectInvitation() async -> Result<Void, RoomProxyError> {
        do {
            return try await .success(room.leave())
        } catch {
            MXLog.error("Failed rejecting invitiation with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
