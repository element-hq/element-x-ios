//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

class SpaceRoomProxy: SpaceRoomProxyProtocol {
    private let spaceRoom: SpaceRoom
    
    init(spaceRoom: SpaceRoom) {
        self.spaceRoom = spaceRoom
    }
    
    lazy var id = spaceRoom.roomId
    var name: String { spaceRoom.displayName }
    var rawName: String? { spaceRoom.rawName }
    var avatarURL: URL? { spaceRoom.avatarUrl.flatMap(URL.init) }
    
    var isSpace: Bool { spaceRoom.roomType == .space }
    var isDirect: Bool? { spaceRoom.isDirect }
    var childrenCount: Int { Int(spaceRoom.childrenCount) }
    
    var joinedMembersCount: Int { Int(spaceRoom.numJoinedMembers) }
    var heroes: [UserProfileProxy] { (spaceRoom.heroes ?? []).map(UserProfileProxy.init) }
    var topic: String? { spaceRoom.topic }
    var canonicalAlias: String? { spaceRoom.canonicalAlias }
    
    var joinRule: JoinRule? { spaceRoom.joinRule }
    var worldReadable: Bool? { spaceRoom.worldReadable }
    var guestCanJoin: Bool { spaceRoom.guestCanJoin }
    var state: Membership? { spaceRoom.state }
    var via: [String] { spaceRoom.via }
}
