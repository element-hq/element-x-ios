//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import UIKit

class InvitedRoomProxy: InvitedRoomProxyProtocol {
    private let roomListItem: RoomListItemProtocol
    private let room: RoomProtocol
    
    // A room identifier is constant and lazy stops it from being fetched
    // multiple times over FFI
    lazy var id: String = room.id()
    
    var canonicalAlias: String? {
        room.canonicalAlias()
    }
    
    var ownUserID: String {
        room.ownUserId()
    }
    
    var name: String? {
        roomListItem.displayName()
    }
        
    var topic: String? {
        room.topic()
    }
    
    var avatarURL: URL? {
        roomListItem.avatarUrl().flatMap(URL.init(string:))
    }
    
    var avatar: RoomAvatar {
        if isDirect, avatarURL == nil {
            let heroes = room.heroes()
            
            if heroes.count == 1 {
                return .heroes(heroes.map(UserProfileProxy.init))
            }
        }
        
        return .room(id: id, name: name, avatarURL: avatarURL)
    }
    
    var isDirect: Bool {
        room.isDirect()
    }
    
    var isPublic: Bool {
        room.isPublic()
    }
    
    var isSpace: Bool {
        room.isSpace()
    }
    
    var joinedMembersCount: Int {
        Int(room.joinedMembersCount())
    }
    
    var activeMembersCount: Int {
        Int(room.activeMembersCount())
    }
    
    var inviter: RoomMemberProxyProtocol? {
        get async {
            await (try? roomListItem.roomInfo().inviter).map(RoomMemberProxy.init)
        }
    }
    
    init(roomListItem: RoomListItemProtocol,
         room: RoomProtocol) {
        self.roomListItem = roomListItem
        self.room = room
    }
    
    func acceptInvitation() async -> Result<Void, RoomProxyError> {
        do {
            try await room.join()
            return .success(())
        } catch {
            MXLog.error("Failed accepting invitation with error: \(error)")
            return .failure(.sdkError(error))
        }
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
