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
    private let roomPreview: RoomPreviewProtocol
    let info: BaseRoomInfoProxyProtocol
    let ownUserID: String
    
    // A room identifier is constant and lazy stops it from being fetched
    // multiple times over FFI
    lazy var id = info.id
        
    init(roomListItem: RoomListItemProtocol,
         roomPreview: RoomPreviewProtocol,
         ownUserID: String) throws {
        self.roomListItem = roomListItem
        self.roomPreview = roomPreview
        self.ownUserID = ownUserID
        info = try RoomPreviewInfoProxy(roomPreviewInfo: roomPreview.info())
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
