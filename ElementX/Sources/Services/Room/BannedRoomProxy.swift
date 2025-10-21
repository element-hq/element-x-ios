//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

class BannedRoomProxy: BannedRoomProxyProtocol {
    private let room: Room
    
    lazy var id = room.id()
    lazy var ownUserID = room.ownUserId()
    
    let info: BaseRoomInfoProxyProtocol
        
    init(room: Room) async throws {
        self.room = room
        
        info = try await RoomInfoProxy(roomInfo: room.roomInfo())
    }
    
    func forgetRoom() async -> Result<Void, RoomProxyError> {
        do {
            return try await .success(room.forget())
        } catch {
            MXLog.error("Failed forgetting the room with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
