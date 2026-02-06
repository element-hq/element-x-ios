//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

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
    static func mockRoomsWithSpace(spaceServiceRoom: SpaceServiceRoom, isLastOwner: Bool, areCreatorsPrivileged: Bool) -> [LeaveSpaceRoom] {
        mockRooms + mockSingleSpace(spaceServiceRoom: spaceServiceRoom, isLastOwner: isLastOwner, areCreatorsPrivileged: areCreatorsPrivileged)
    }
    
    static func mockSingleSpace(spaceServiceRoom: SpaceServiceRoom, isLastOwner: Bool, areCreatorsPrivileged: Bool) -> [LeaveSpaceRoom] {
        [LeaveSpaceRoom(spaceRoom: SpaceRoom(id: spaceServiceRoom.id,
                                             name: spaceServiceRoom.name,
                                             avatarURL: spaceServiceRoom.avatarURL,
                                             isSpace: true,
                                             memberCount: UInt64(spaceServiceRoom.joinedMembersCount),
                                             joinRule: spaceServiceRoom.joinRule),
                        isLastOwner: isLastOwner,
                        areCreatorsPrivileged: areCreatorsPrivileged)]
    }
    
    static var mockNeedNewOwnerRooms: [LeaveSpaceRoom] {
        mockRooms.filter { $0.isLastOwner && $0.spaceRoom.numJoinedMembers > 1 }
    }
    
    static var mockRooms: [LeaveSpaceRoom] {
        [
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "1",
                                                name: "Lighting",
                                                avatarURL: .mockMXCAvatar,
                                                isSpace: false,
                                                memberCount: 10,
                                                joinRule: .public),
                           isLastOwner: false,
                           areCreatorsPrivileged: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "2",
                                                name: "Sound",
                                                isSpace: false,
                                                memberCount: 20,
                                                joinRule: .invite),
                           isLastOwner: false,
                           areCreatorsPrivileged: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "3",
                                                name: "Set & Costume",
                                                isSpace: false,
                                                memberCount: 25,
                                                joinRule: .restricted(rules: [])),
                           isLastOwner: false,
                           areCreatorsPrivileged: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "4",
                                                name: "The Theatre",
                                                isSpace: true,
                                                memberCount: 100,
                                                joinRule: .invite,
                                                childrenCount: 20),
                           isLastOwner: false,
                           areCreatorsPrivileged: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "5",
                                                name: "Bookings",
                                                isSpace: false,
                                                memberCount: 200,
                                                joinRule: .invite,
                                                childrenCount: 0),
                           isLastOwner: true,
                           areCreatorsPrivileged: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "6",
                                                name: "Events",
                                                isSpace: false,
                                                memberCount: 65,
                                                joinRule: .restricted(rules: []),
                                                childrenCount: 0),
                           isLastOwner: true,
                           areCreatorsPrivileged: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "7",
                                                name: "Mario Kart",
                                                isSpace: false,
                                                memberCount: 123,
                                                joinRule: .public),
                           isLastOwner: false,
                           areCreatorsPrivileged: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "8",
                                                name: "Tetris",
                                                isSpace: false,
                                                memberCount: 95,
                                                joinRule: .public),
                           isLastOwner: false,
                           areCreatorsPrivileged: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "9",
                                                name: "Minecraft",
                                                isSpace: false,
                                                memberCount: 39,
                                                joinRule: .public),
                           isLastOwner: false,
                           areCreatorsPrivileged: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "10",
                                                name: "Lemmings",
                                                isSpace: false,
                                                memberCount: 67,
                                                joinRule: .public),
                           isLastOwner: true,
                           areCreatorsPrivileged: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "11",
                                                name: "Rayman",
                                                isSpace: false,
                                                memberCount: 23,
                                                joinRule: .public),
                           isLastOwner: false,
                           areCreatorsPrivileged: false),
            LeaveSpaceRoom(spaceRoom: SpaceRoom(id: "12",
                                                name: "Gaming",
                                                avatarURL: .mockMXCAvatar,
                                                isSpace: true,
                                                memberCount: 835,
                                                joinRule: .public,
                                                childrenCount: 15),
                           isLastOwner: true,
                           areCreatorsPrivileged: false)
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
                  joinRule: joinRule?.rustValue,
                  worldReadable: true,
                  guestCanJoin: false,
                  isDirect: isDirect,
                  childrenCount: childrenCount,
                  state: membership,
                  heroes: heroes,
                  via: via)
    }
}
