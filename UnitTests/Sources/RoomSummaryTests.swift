//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

class RoomSummaryTests: XCTestCase {
    // swiftlint:disable:next large_tuple
    let roomDetails: (id: String, name: String, avatarURL: URL) = ("room_id", "Room Name", "mxc://hs.tld/room/avatar")
    let heroes = [UserProfileProxy(userID: "hero_1", displayName: "Hero 1", avatarURL: "mxc://hs.tld/user/avatar")]
    
    func testRoomAvatar() {
        let details = makeSummary(isDirect: false, hasRoomAvatar: true)
        
        switch details.avatar {
        case .room(let id, let name, let avatarURL):
            XCTAssertEqual(id, roomDetails.id)
            XCTAssertEqual(name, roomDetails.name)
            XCTAssertEqual(avatarURL, roomDetails.avatarURL)
        case .heroes:
            XCTFail("A room shouldn't use the heroes for its avatar.")
        }
    }
    
    func testDMAvatarSet() {
        let details = makeSummary(isDirect: true, hasRoomAvatar: true)
        
        switch details.avatar {
        case .room(let id, let name, let avatarURL):
            XCTAssertEqual(id, roomDetails.id)
            XCTAssertEqual(name, roomDetails.name)
            XCTAssertEqual(avatarURL, roomDetails.avatarURL)
        case .heroes:
            XCTFail("A DM with an avatar set shouldn't use the heroes instead.")
        }
    }
    
    func testDMAvatarNotSet() {
        let details = makeSummary(isDirect: true, hasRoomAvatar: false)
        
        switch details.avatar {
        case .room:
            XCTFail("A DM without an avatar should defer to the hero for the correct placeholder tint colour.")
        case .heroes(let heroes):
            XCTAssertEqual(heroes, self.heroes)
        }
    }
    
    // MARK: - Helpers
    
    func makeSummary(isDirect: Bool, hasRoomAvatar: Bool) -> RoomSummary {
        RoomSummary(roomListItem: .init(noPointer: .init()),
                    id: roomDetails.id,
                    isInvite: false,
                    inviter: nil,
                    name: roomDetails.name,
                    isDirect: isDirect,
                    avatarURL: hasRoomAvatar ? roomDetails.avatarURL : nil,
                    heroes: heroes,
                    lastMessage: nil,
                    lastMessageFormattedTimestamp: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: nil,
                    canonicalAlias: nil,
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false)
    }
}
