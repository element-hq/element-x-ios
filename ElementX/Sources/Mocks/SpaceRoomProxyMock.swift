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
        var isDirect: Bool?
        var parent: SpaceRoomProxyProtocol?
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
        isDirect = configuration.isDirect
        parent = configuration.parent
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

extension [SpaceRoomProxyProtocol] {
    static var mockJoinedSpaces: [SpaceRoomProxyMock] {
        [
            SpaceRoomProxyMock(.init(id: "space1",
                                     name: "The Foundation",
                                     isSpace: true,
                                     childrenCount: 1,
                                     joinedMembersCount: 500,
                                     state: .joined)),
            SpaceRoomProxyMock(.init(id: "space2",
                                     name: "The Second Foundation",
                                     isSpace: true,
                                     childrenCount: 1,
                                     joinedMembersCount: 100,
                                     state: .joined)),
            SpaceRoomProxyMock(.init(id: "space3",
                                     name: "The Galactic Empire",
                                     isSpace: true,
                                     childrenCount: 25000,
                                     joinedMembersCount: 1_000_000_000,
                                     state: .joined)),
            SpaceRoomProxyMock(.init(id: "space4",
                                     name: "The Korellians",
                                     isSpace: true,
                                     childrenCount: 27,
                                     joinedMembersCount: 2_000_000,
                                     state: .joined)),
            SpaceRoomProxyMock(.init(id: "space5",
                                     name: "The Luminists",
                                     isSpace: true,
                                     childrenCount: 1,
                                     joinedMembersCount: 100_000,
                                     state: .joined)),
            SpaceRoomProxyMock(.init(id: "space6",
                                     name: "The Anacreons",
                                     isSpace: true,
                                     childrenCount: 25,
                                     joinedMembersCount: 400_000,
                                     state: .joined)),
            SpaceRoomProxyMock(.init(id: "space7",
                                     name: "The Thespians",
                                     isSpace: true,
                                     childrenCount: 15,
                                     joinedMembersCount: 300_000,
                                     state: .joined))
        ]
    }
    
    static var mockSpaceList: [SpaceRoomProxyProtocol] {
        makeSpaceRooms(isSpace: true) + makeSpaceRooms(isSpace: false)
    }
    
    static var mockSingleRoom: [SpaceRoomProxyProtocol] {
        [SpaceRoomProxyMock(.init(id: "!spaceroom:matrix.org",
                                  name: "Management",
                                  isSpace: false,
                                  joinedMembersCount: 12,
                                  topic: "This is where everything gets organised 📋.",
                                  state: .joined))]
    }
    
    private static func makeSpaceRooms(isSpace: Bool) -> [SpaceRoomProxyMock] {
        let typeName = isSpace ? "Space" : "Room"
        
        return [
            SpaceRoomProxyMock(.init(id: "!\(typeName.lowercased())1:matrix.org",
                                     name: "Company \(typeName)",
                                     isSpace: isSpace)),
            SpaceRoomProxyMock(.init(id: "!\(typeName.lowercased())2:matrix.org",
                                     name: "Public \(typeName)",
                                     avatarURL: .mockMXCAvatar,
                                     isSpace: isSpace,
                                     joinedMembersCount: 78,
                                     topic: "Discussion on specific topic goes here.",
                                     joinRule: .public)),
            SpaceRoomProxyMock(.init(id: "!\(typeName.lowercased())3:matrix.org",
                                     name: "Joined \(typeName)",
                                     isSpace: isSpace,
                                     parent: SpaceRoomProxyMock(.init(name: "Company", isSpace: true)),
                                     joinedMembersCount: 123,
                                     topic: "Discussion on specific topic goes here.",
                                     joinRule: .restricted(rules: []),
                                     state: .joined))
        ]
    }
}
