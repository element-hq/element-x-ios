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
    private let roomPreview: RoomPreviewProtocol
    let info: BaseRoomInfoProxyProtocol
    
    // A room identifier is constant and lazy stops it from being fetched
    // multiple times over FFI
    var id: String {
        info.id
    }
    
    let ownUserID: String
    
    init(roomListItem: RoomListItemProtocol,
         roomPreview: RoomPreviewProtocol,
         ownUserID: String) async throws {
        self.roomListItem = roomListItem
        self.roomPreview = roomPreview
        self.ownUserID = ownUserID
        info = try RoomPreviewInfoProxy(roomPreviewInfo: roomPreview.info())
    }
    
    func cancelKnock() async -> Result<Void, RoomProxyError> {
        do {
            return try await .success(roomPreview.leave())
        } catch {
            MXLog.error("Failed cancelling the knock with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
