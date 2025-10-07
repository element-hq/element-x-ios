//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension LeaveSpaceHandleSDKMock {
    struct Configuration {
        var rooms: [LeaveSpaceRoom] = .mockRooms
    }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        roomsClosure = { configuration.rooms }
    }
}

extension [LeaveSpaceRoom] {
    static func mockLastSpaceAdmin(spaceRoomProxy: SpaceRoomProxyProtocol) -> [LeaveSpaceRoom] {
        mockRooms + [LeaveSpaceRoom(spaceRoom: SpaceRoom(id: spaceRoomProxy.id,
                                                         name: spaceRoomProxy.name,
                                                         avatarURL: spaceRoomProxy.avatarURL,
                                                         isSpace: true,
                                                         memberCount: UInt64(spaceRoomProxy.joinedMembersCount),
                                                         joinRule: spaceRoomProxy.joinRule),
                                    isLastAdmin: true)]
    }
    
    static var mockAdminRooms: [LeaveSpaceRoom] {
        mockRooms.filter(\.isLastAdmin)
    }
    
    static var mockRooms: [LeaveSpaceRoom] {
        [
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "1",
                                                name: "Lighting",
                                                avatarURL: .mockMXCAvatar,
                                                isSpace: false,
                                                memberCount: 10,
                                                joinRule: .public),
                           isLastAdmin: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "2",
                                                name: "Sound",
                                                isSpace: false,
                                                memberCount: 20,
                                                joinRule: .private),
                           isLastAdmin: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "3",
                                                name: "Set & Costume",
                                                isSpace: false,
                                                memberCount: 25,
                                                joinRule: .restricted(rules: [])),
                           isLastAdmin: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "4",
                                                name: "The Theatre",
                                                isSpace: true,
                                                memberCount: 100,
                                                joinRule: .private,
                                                childrenCount: 20),
                           isLastAdmin: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "5",
                                                name: "Bookings",
                                                isSpace: false,
                                                memberCount: 200,
                                                joinRule: .private,
                                                childrenCount: 0),
                           isLastAdmin: true),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "6",
                                                name: "Events",
                                                isSpace: false,
                                                memberCount: 65,
                                                joinRule: .restricted(rules: []),
                                                childrenCount: 0),
                           isLastAdmin: true),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "7",
                                                name: "Mario Kart",
                                                isSpace: false,
                                                memberCount: 123,
                                                joinRule: .public),
                           isLastAdmin: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "8",
                                                name: "Tetris",
                                                isSpace: false,
                                                memberCount: 95,
                                                joinRule: .public),
                           isLastAdmin: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "9",
                                                name: "Minecraft",
                                                isSpace: false,
                                                memberCount: 39,
                                                joinRule: .public),
                           isLastAdmin: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "10",
                                                name: "Lemmings",
                                                isSpace: false,
                                                memberCount: 67,
                                                joinRule: .public),
                           isLastAdmin: true),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "11",
                                                name: "Rayman",
                                                isSpace: false,
                                                memberCount: 23,
                                                joinRule: .public),
                           isLastAdmin: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "12",
                                                name: "Gaming",
                                                avatarURL: .mockMXCAvatar,
                                                isSpace: true,
                                                memberCount: 835,
                                                joinRule: .public,
                                                childrenCount: 15),
                           isLastAdmin: true)
        ]
    }
}

private extension SpaceRoom {
    init(id: String,
         canonicalAlias: String? = nil,
         name: String,
         topic: String? = nil,
         avatarURL: URL? = nil,
         isSpace: Bool,
         memberCount: UInt64,
         joinRule: JoinRule? = .public,
         isDirect: Bool? = false,
         childrenCount: UInt64 = 0,
         membership: Membership? = .joined,
         heroes: [RoomHero]? = [],
         via: [String] = []) {
        self.init(roomId: id,
                  canonicalAlias: canonicalAlias,
                  displayName: name,
                  rawName: name,
                  topic: topic,
                  avatarUrl: avatarURL?.absoluteString,
                  roomType: isSpace ? .space : .room,
                  numJoinedMembers: memberCount,
                  joinRule: joinRule,
                  worldReadable: true,
                  guestCanJoin: false,
                  isDirect: isDirect,
                  childrenCount: childrenCount,
                  state: membership,
                  heroes: heroes,
                  via: via)
    }
}
