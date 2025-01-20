//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension RoomPreviewProxyMock {
    struct Configuration {
        var roomID = "1"
        var canonicalAlias = "#3🌞problem:matrix.org"
        var name = "The Three-Body Problem - 三体"
        var topic = "“Science and technology were the only keys to opening the door to the future, and people approached science with the faith and sincerity of elementary school students.”"
        var avatarURL = URL.mockMXCAvatar.absoluteString
        var numJoinedMembers = UInt64(100)
        var numActiveMembers = UInt64(100)
        var roomType = RoomType.room
        var membership: Membership?
        var joinRule: JoinRule
    }
    
    static var joinable: RoomPreviewProxyMock {
        .init(.init(membership: nil, joinRule: .public))
    }
    
    static var restricted: RoomPreviewProxyMock {
        .init(.init(membership: nil, joinRule: .restricted(rules: [])))
    }
    
    static var inviteRequired: RoomPreviewProxyMock {
        .init(.init(membership: nil, joinRule: .invite))
    }
    
    static func invited(roomID: String? = nil) -> RoomPreviewProxyMock {
        if let roomID {
            return .init(.init(roomID: roomID, membership: .invited, joinRule: .invite))
        }
        
        return .init(.init(membership: .invited, joinRule: .invite))
    }
    
    static var knockable: RoomPreviewProxyMock {
        .init(.init(membership: nil, joinRule: .knock))
    }
    
    static var knockableRestricted: RoomPreviewProxyMock {
        .init(.init(membership: nil, joinRule: .knockRestricted(rules: [])))
    }
    
    static var knocked: RoomPreviewProxyMock {
        .init(.init(membership: .knocked, joinRule: .knock))
    }
    
    static var banned: RoomPreviewProxyMock {
        .init(.init(membership: .banned, joinRule: .public))
    }
    
    convenience init(_ configuration: RoomPreviewProxyMock.Configuration) {
        self.init()
        underlyingInfo = .init(roomPreviewInfo: .init(roomId: configuration.roomID,
                                                      canonicalAlias: configuration.canonicalAlias,
                                                      name: configuration.name,
                                                      topic: configuration.topic,
                                                      avatarUrl: configuration.avatarURL,
                                                      numJoinedMembers: configuration.numJoinedMembers,
                                                      numActiveMembers: configuration.numActiveMembers,
                                                      roomType: configuration.roomType,
                                                      isHistoryWorldReadable: nil,
                                                      membership: configuration.membership,
                                                      joinRule: configuration.joinRule,
                                                      isDirect: nil,
                                                      heroes: nil))
        
        let roomMembershipDetails = RoomMembershipDetailsProxyMock()
        
        let mockMember = RoomMemberProxyMock()
        mockMember.userID = "@bob:matrix.org"
        mockMember.displayName = "Billy Bob"
        mockMember.avatarURL = .mockMXCUserAvatar
        mockMember.membershipChangeReason = "Ain't nobody need no reason"
        
        roomMembershipDetails.senderRoomMember = mockMember
        roomMembershipDetails.ownRoomMember = mockMember
        
        underlyingOwnMembershipDetails = roomMembershipDetails
    }
}
