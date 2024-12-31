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
    private let roomPreview: RoomPreviewProtocol
    let info: BaseRoomInfoProxyProtocol
    let ownUserID: String
    let inviter: RoomMemberProxyProtocol?
    
    // A room identifier is constant and lazy stops it from being fetched
    // multiple times over FFI
    lazy var id: String = info.id
        
    init(roomListItem: RoomListItemProtocol,
         roomPreview: RoomPreviewProtocol,
         ownUserID: String) async throws {
        self.roomListItem = roomListItem
        self.roomPreview = roomPreview
        self.ownUserID = ownUserID
        info = try RoomPreviewInfoProxy(roomPreviewInfo: roomPreview.info())
        inviter = await roomPreview.inviter().map(RoomMemberProxy.init)
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
