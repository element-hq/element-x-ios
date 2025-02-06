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
    
    var inviter: RoomMemberProxyProtocol? {
        get async throws {
            try await roomPreview.inviter().map(RoomMemberProxy.init)
        }
    }
    
    let ownUserID: String
    
    // A room identifier is constant and lazy stops it from being fetched
    // multiple times over FFI
    lazy var id: String = roomListItem.id()
        
    init(roomListItem: RoomListItemProtocol,
         ownUserID: String) {
        self.roomListItem = roomListItem
        self.ownUserID = ownUserID
        roomPreviewTask = Task {
            try await roomListItem.previewRoom(via: [])
        }
    }
    
    func rejectInvitation() async -> Result<Void, RoomProxyError> {
        do {
            return try await .success(roomPreview.leave())
        } catch {
            MXLog.error("Failed rejecting invitiation with error: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
