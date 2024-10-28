//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import UIKit

class KnockedRoomProxy: KnockedRoomProxyProtocol {
    private let roomListItem: RoomListItemProtocol
    private let room: RoomProtocol
    
    // A room identifier is constant and lazy stops it from being fetched
    // multiple times over FFI
    lazy var id: String = room.id()
    
    var ownUserID: String { room.ownUserId() }
    
    let info: RoomInfoProxy
    
    init(roomListItem: RoomListItemProtocol,
         room: RoomProtocol) async throws {
        self.roomListItem = roomListItem
        self.room = room
        info = try await RoomInfoProxy(roomInfo: room.roomInfo())
    }
    
    func cancelKnock() async -> Result<Void, RoomProxyError> {
        do {
            return try await .success(room.leave())
        } catch {
            MXLog.error("Failed cancelling the knock with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
