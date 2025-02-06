//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

class BannedRoomProxy: BannedRoomProxyProtocol {
    private let roomListItem: RoomListItemProtocol
    private var roomPreview: RoomPreviewProtocol {
        get async throws {
            try await roomPreviewTask.value
        }
    }
    
    private var roomPreviewTask: Task<RoomPreviewProtocol, Error>
    
    var info: BaseRoomInfoProxyProtocol {
        get async throws {
            try await RoomPreviewInfoProxy(roomPreviewInfo: roomPreview.info())
        }
    }
    
    let ownUserID: String
    
    // A room identifier is constant and lazy stops it from being fetched
    // multiple times over FFI
    lazy var id = roomListItem.id()
        
    init(roomListItem: RoomListItemProtocol,
         ownUserID: String) {
        self.roomListItem = roomListItem
        self.ownUserID = ownUserID
        roomPreviewTask = Task { try await roomListItem.previewRoom(via: []) }
    }
    
    func forgetRoom() async -> Result<Void, RoomProxyError> {
        do {
            return try await .success(roomPreview.forget())
        } catch {
            MXLog.error("Failed forgetting the room with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
