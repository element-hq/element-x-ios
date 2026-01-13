//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension SpaceServiceRoomMock {
    struct Configuration {
        var id: String = UUID().uuidString
        var name: String?
        var rawName: String?
        var avatarURL: URL?
        
        var isSpace: Bool
        var isDirect: Bool?
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
        name = configuration.name ?? configuration.id
        rawName = configuration.rawName
        avatarURL = configuration.avatarURL
        isSpace = configuration.isSpace
        isDirect = configuration.isDirect
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

extension [SpaceServiceRoomProtocol] {
    static var mockJoinedSpaces: [SpaceServiceRoomMock] {
        [
            SpaceServiceRoomMock(.init(id: "space1",
                                       name: "The Foundation",
                                       isSpace: true,
                                       childrenCount: 1,
                                       joinedMembersCount: 500,
                                       state: .joined)),
            SpaceServiceRoomMock(.init(id: "space2",
                                       name: "The Second Foundation",
                                       isSpace: true,
                                       childrenCount: 1,
                                       joinedMembersCount: 100,
                                       state: .joined)),
            SpaceServiceRoomMock(.init(id: "space3",
                                       name: "The Galactic Empire",
                                       isSpace: true,
                                       childrenCount: 25000,
                                       joinedMembersCount: 1_000_000_000,
                                       state: .joined)),
            SpaceServiceRoomMock(.init(id: "space4",
                                       name: "The Korellians",
                                       isSpace: true,
                                       childrenCount: 27,
                                       joinedMembersCount: 2_000_000,
                                       state: .joined)),
            SpaceServiceRoomMock(.init(id: "space5",
                                       name: "The Luminists",
                                       isSpace: true,
                                       childrenCount: 1,
                                       joinedMembersCount: 100_000,
                                       state: .joined)),
            SpaceServiceRoomMock(.init(id: "space6",
                                       name: "The Anacreons",
                                       isSpace: true,
                                       childrenCount: 25,
                                       joinedMembersCount: 400_000,
                                       state: .joined)),
            SpaceServiceRoomMock(.init(id: "space7",
                                       name: "The Thespians",
                                       isSpace: true,
                                       childrenCount: 15,
                                       joinedMembersCount: 300_000,
                                       state: .joined))
        ]
    }
    
    static var mockJoinedSpaces2: [SpaceServiceRoomMock] {
        [
            SpaceServiceRoomMock(.init(id: "space1",
                                       name: "The Foundation",
                                       avatarURL: .mockMXCAvatar,
                                       isSpace: true,
                                       childrenCount: 1,
                                       joinedMembersCount: 500,
                                       canonicalAlias: "#the-foundation:matrix.org",
                                       state: .joined)),
            SpaceServiceRoomMock(.init(id: "space2",
                                       name: "The Second Foundation",
                                       isSpace: true,
                                       childrenCount: 1,
                                       joinedMembersCount: 100,
                                       state: .joined)),
            SpaceServiceRoomMock(.init(id: "space3",
                                       name: "The Galactic Empire",
                                       isSpace: true,
                                       childrenCount: 25000,
                                       joinedMembersCount: 1_000_000_000,
                                       canonicalAlias: "#the-galactic-empire:matrix.org",
                                       state: .joined))
        ]
    }
    
    static var mockSpaceList: [SpaceServiceRoomProtocol] {
        makeSpaceRooms(isSpace: true) + makeSpaceRooms(isSpace: false)
    }
    
    static var mockSingleRoom: [SpaceServiceRoomProtocol] {
        [SpaceServiceRoomMock(.init(id: "!spaceroom:matrix.org",
                                    name: "Management",
                                    isSpace: false,
                                    joinedMembersCount: 12,
                                    topic: "This is where everything gets organised 📋.",
                                    state: .joined))]
    }
    
    private static func makeSpaceRooms(isSpace: Bool) -> [SpaceServiceRoomMock] {
        let typeName = isSpace ? "Space" : "Room"
        
        return [
            SpaceServiceRoomMock(.init(id: "!\(typeName.lowercased())1:matrix.org",
                                       name: "Company \(typeName)",
                                       isSpace: isSpace)),
            SpaceServiceRoomMock(.init(id: "!\(typeName.lowercased())2:matrix.org",
                                       name: "Public \(typeName)",
                                       avatarURL: .mockMXCAvatar,
                                       isSpace: isSpace,
                                       joinedMembersCount: 78,
                                       topic: "Discussion on specific topic goes here.",
                                       joinRule: .public)),
            SpaceServiceRoomMock(.init(id: "!\(typeName.lowercased())3:matrix.org",
                                       name: "Joined \(typeName)",
                                       isSpace: isSpace,
                                       joinedMembersCount: 123,
                                       topic: "Discussion on specific topic goes here.",
                                       joinRule: .restricted(rules: []),
                                       state: .joined))
        ]
    }
}

extension SpaceServiceRoomMock {
    convenience init(mode: JoinRoomScreenMode) {
        var state: Membership?
        var joinRule: JoinRule?
        
        switch mode {
        case .joinable:
            joinRule = .public
        case .restricted:
            joinRule = .restricted(rules: [])
        case .inviteRequired:
            joinRule = .private
        case .invited:
            state = .invited
            joinRule = .private
        case .knockable:
            joinRule = .knock
        case .knocked:
            state = .knocked
            joinRule = .knock
        case .banned:
            state = .banned
        case .loading, .unknown, .forbidden:
            break
        }
        
        self.init(.init(id: "1",
                        name: "The Three-Body Problem",
                        avatarURL: .mockMXCAvatar,
                        isSpace: true,
                        childrenCount: 100,
                        joinedMembersCount: 123,
                        heroes: [.mockAlice, .mockBob, .mockCharlie],
                        topic: "“Science and technology were the only keys to opening the door to the future, and people approached science with the faith and sincerity of elementary school students.”",
                        canonicalAlias: "#3-body-problem:matrix.org",
                        joinRule: joinRule,
                        state: state))
    }
}
