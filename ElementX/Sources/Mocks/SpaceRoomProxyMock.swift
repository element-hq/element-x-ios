//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension SpaceRoomProxyMock {
    struct Configuration {
        var id: String = UUID().uuidString
        var name: String?
        var avatarURL: URL?
        
        var isSpace: Bool
        var childrenCount = 0
        
        var joinedMembersCount = 0
        var heroes: [UserProfileProxy] = []
        var topic: String?
        var canonicalAlias: String?
        
        var joinRule: JoinRule?
        var worldReadable: Bool?
        var guestCanJoin = true
        var state: Membership?
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        id = configuration.id
        name = configuration.name
        avatarURL = configuration.avatarURL
        isSpace = configuration.isSpace
        childrenCount = configuration.childrenCount
        joinedMembersCount = configuration.joinedMembersCount
        heroes = configuration.heroes
        topic = configuration.topic
        canonicalAlias = configuration.canonicalAlias
        joinRule = configuration.joinRule
        worldReadable = configuration.worldReadable
        guestCanJoin = configuration.guestCanJoin
        state = configuration.state
    }
}
