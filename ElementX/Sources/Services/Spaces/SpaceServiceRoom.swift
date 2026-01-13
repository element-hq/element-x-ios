//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct SpaceServiceRoom: SpaceServiceRoomProtocol {
    var id: String
    var name: String
    var rawName: String?
    var avatarURL: URL?
    
    var isSpace: Bool
    var isDirect: Bool?
    var childrenCount: Int
    
    var joinedMembersCount: Int
    var heroes: [UserProfileProxy]
    var topic: String?
    var canonicalAlias: String?
    
    var joinRule: JoinRule?
    var worldReadable: Bool?
    var guestCanJoin: Bool
    var state: Membership?
    var via: [String]
    
    init(spaceRoom: SpaceRoom) {
        id = spaceRoom.roomId
        name = spaceRoom.displayName
        rawName = spaceRoom.rawName
        avatarURL = spaceRoom.avatarUrl.flatMap(URL.init)
        
        isSpace = spaceRoom.roomType == .space
        isDirect = spaceRoom.isDirect
        childrenCount = Int(spaceRoom.childrenCount)
        
        joinedMembersCount = Int(spaceRoom.numJoinedMembers)
        heroes = (spaceRoom.heroes ?? []).map(UserProfileProxy.init)
        topic = spaceRoom.topic
        canonicalAlias = spaceRoom.canonicalAlias
        
        joinRule = spaceRoom.joinRule
        worldReadable = spaceRoom.worldReadable
        guestCanJoin = spaceRoom.guestCanJoin
        state = spaceRoom.state
        via = spaceRoom.via
    }
}
