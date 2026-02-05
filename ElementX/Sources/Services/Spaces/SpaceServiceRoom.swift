//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

enum SpaceServiceRoomVisibility: Equatable {
    case `public`
    case `private`
    case restricted
    // We can add the external case in here eventually.
}

struct SpaceServiceRoom {
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
    
    var avatar: RoomAvatar {
        if isSpace {
            .space(id: id, name: name, avatarURL: avatarURL)
        } else if isDirect == true, avatarURL == nil, heroes.count == 1 {
            .heroes(heroes)
        } else {
            .room(id: id, name: name, avatarURL: avatarURL)
        }
    }
    
    var visibility: SpaceServiceRoomVisibility? {
        switch joinRule {
        case .public:
            .public
        case .restricted, .knockRestricted:
            .restricted
        case .invite, .knock, .custom:
            .private
        case .none:
            .none
        }
    }
}
    
extension SpaceServiceRoom {
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
        
        joinRule = spaceRoom.joinRule.map(JoinRule.init)
        worldReadable = spaceRoom.worldReadable
        guestCanJoin = spaceRoom.guestCanJoin
        state = spaceRoom.state
        via = spaceRoom.via
    }
    
    // MARK: - Mocks
    
    static func mock(id: String = UUID().uuidString,
                     name: String? = nil,
                     rawName: String? = nil,
                     avatarURL: URL? = nil,
                     isSpace: Bool,
                     isDirect: Bool? = nil,
                     childrenCount: Int = 0,
                     joinedMembersCount: Int = 0,
                     heroes: [UserProfileProxy] = [],
                     topic: String? = nil,
                     canonicalAlias: String? = nil,
                     joinRule: JoinRule? = nil,
                     worldReadable: Bool? = nil,
                     guestCanJoin: Bool = true,
                     state: Membership? = nil,
                     via: [String] = []) -> Self {
        SpaceServiceRoom(id: id,
                         name: name ?? id,
                         rawName: rawName,
                         avatarURL: avatarURL,
                         isSpace: isSpace,
                         isDirect: isDirect,
                         childrenCount: childrenCount,
                         joinedMembersCount: joinedMembersCount,
                         heroes: heroes,
                         topic: topic,
                         canonicalAlias: canonicalAlias,
                         joinRule: joinRule,
                         worldReadable: worldReadable,
                         guestCanJoin: guestCanJoin,
                         state: state,
                         via: via)
    }
    
    static func mock(joinRoomScreenMode: JoinRoomScreenMode) -> Self {
        var state: Membership?
        var joinRule: JoinRule?
        
        switch joinRoomScreenMode {
        case .joinable:
            joinRule = .public
        case .restricted:
            joinRule = .restricted(rules: [])
        case .inviteRequired:
            joinRule = .invite
        case .invited:
            state = .invited
            joinRule = .invite
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
        
        return SpaceServiceRoom.mock(id: "1",
                                     name: "The Three-Body Problem",
                                     avatarURL: .mockMXCAvatar,
                                     isSpace: true,
                                     childrenCount: 100,
                                     joinedMembersCount: 123,
                                     heroes: [.mockAlice, .mockBob, .mockCharlie],
                                     topic: "“Science and technology were the only keys to opening the door to the future, and people approached science with the faith and sincerity of elementary school students.”",
                                     canonicalAlias: "#3-body-problem:matrix.org",
                                     joinRule: joinRule,
                                     state: state)
    }
}

extension [SpaceServiceRoom] {
    static var mockJoinedSpaces: [SpaceServiceRoom] {
        [
            SpaceServiceRoom.mock(id: "space1",
                                  name: "The Foundation",
                                  isSpace: true,
                                  childrenCount: 1,
                                  joinedMembersCount: 500,
                                  canonicalAlias: "#the-foundation:matrix.org",
                                  state: .joined),
            SpaceServiceRoom.mock(id: "space2",
                                  name: "The Second Foundation",
                                  isSpace: true,
                                  childrenCount: 1,
                                  joinedMembersCount: 100,
                                  state: .joined),
            SpaceServiceRoom.mock(id: "space3",
                                  name: "The Galactic Empire",
                                  isSpace: true,
                                  childrenCount: 25000,
                                  joinedMembersCount: 1_000_000_000,
                                  canonicalAlias: "#the-galactic-empire:matrix.org",
                                  state: .joined),
            SpaceServiceRoom.mock(id: "space4",
                                  name: "The Korellians",
                                  isSpace: true,
                                  childrenCount: 27,
                                  joinedMembersCount: 2_000_000,
                                  state: .joined),
            SpaceServiceRoom.mock(id: "space5",
                                  name: "The Luminists",
                                  isSpace: true,
                                  childrenCount: 1,
                                  joinedMembersCount: 100_000,
                                  state: .joined),
            SpaceServiceRoom.mock(id: "space6",
                                  name: "The Anacreons",
                                  isSpace: true,
                                  childrenCount: 25,
                                  joinedMembersCount: 400_000,
                                  state: .joined),
            SpaceServiceRoom.mock(id: "space7",
                                  name: "The Thespians",
                                  isSpace: true,
                                  childrenCount: 15,
                                  joinedMembersCount: 300_000,
                                  state: .joined)
        ]
    }
    
    static var mockJoinedSpaces2: [SpaceServiceRoom] {
        [
            SpaceServiceRoom.mock(id: "space1",
                                  name: "The Foundation",
                                  avatarURL: .mockMXCAvatar,
                                  isSpace: true,
                                  childrenCount: 1,
                                  joinedMembersCount: 500,
                                  canonicalAlias: "#the-foundation:matrix.org",
                                  joinRule: .invite,
                                  state: .joined),
            SpaceServiceRoom.mock(id: "space2",
                                  name: "The Second Foundation",
                                  isSpace: true,
                                  childrenCount: 1,
                                  joinedMembersCount: 100,
                                  state: .joined),
            SpaceServiceRoom.mock(id: "space3",
                                  name: "The Galactic Empire",
                                  isSpace: true,
                                  childrenCount: 25000,
                                  joinedMembersCount: 1_000_000_000,
                                  canonicalAlias: "#the-galactic-empire:matrix.org",
                                  state: .joined)
        ]
    }
    
    static var mockSpaceList: [SpaceServiceRoom] {
        makeSpaceRooms(isSpace: true) + makeSpaceRooms(isSpace: false)
    }
    
    static var mockSingleRoom: [SpaceServiceRoom] {
        [SpaceServiceRoom.mock(id: "!spaceroom:matrix.org",
                               name: "Management",
                               isSpace: false,
                               joinedMembersCount: 12,
                               topic: "This is where everything gets organised 📋.",
                               state: .joined)]
    }
    
    private static func makeSpaceRooms(isSpace: Bool) -> [SpaceServiceRoom] {
        let typeName = isSpace ? "Space" : "Room"
        
        return [
            SpaceServiceRoom.mock(id: "!\(typeName.lowercased())1:matrix.org",
                                  name: "Company \(typeName)",
                                  isSpace: isSpace),
            SpaceServiceRoom.mock(id: "!\(typeName.lowercased())2:matrix.org",
                                  name: "Public \(typeName)",
                                  avatarURL: .mockMXCAvatar,
                                  isSpace: isSpace,
                                  joinedMembersCount: 78,
                                  topic: "Discussion on specific topic goes here.",
                                  joinRule: .public),
            SpaceServiceRoom.mock(id: "!\(typeName.lowercased())3:matrix.org",
                                  name: "Joined \(typeName)",
                                  isSpace: isSpace,
                                  joinedMembersCount: 123,
                                  topic: "Discussion on specific topic goes here.",
                                  joinRule: .restricted(rules: []),
                                  state: .joined)
        ]
    }
}
