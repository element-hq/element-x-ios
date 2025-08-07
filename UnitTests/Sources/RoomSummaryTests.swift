//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

class RoomSummaryTests: XCTestCase {
    // swiftlint:disable:next large_tuple
    let roomDetails: (id: String, name: String, avatarURL: URL) = ("room_id", "Room Name", "mxc://hs.tld/room/avatar")
    let heroes = [UserProfileProxy(userID: "hero_1", displayName: "Hero 1", avatarURL: "mxc://hs.tld/user/avatar")]
    
    func testRoomAvatar() {
        let details = makeSummary(isDirect: false, hasRoomAvatar: true, isTombstoned: false)
        
        switch details.avatar {
        case .room(let id, let name, let avatarURL):
            XCTAssertEqual(id, roomDetails.id)
            XCTAssertEqual(name, roomDetails.name)
            XCTAssertEqual(avatarURL, roomDetails.avatarURL)
        case .heroes:
            XCTFail("A room shouldn't use the heroes for its avatar.")
        case .space:
            XCTFail("A room shouldn't use a space avatar.")
        case .tombstoned:
            XCTFail("A room shouldn't use the tombstone for its avatar.")
        }
    }
    
    func testDMAvatarSet() {
        let details = makeSummary(isDirect: true, hasRoomAvatar: true, isTombstoned: false)
        
        switch details.avatar {
        case .room(let id, let name, let avatarURL):
            XCTAssertEqual(id, roomDetails.id)
            XCTAssertEqual(name, roomDetails.name)
            XCTAssertEqual(avatarURL, roomDetails.avatarURL)
        case .heroes:
            XCTFail("A DM with an avatar set shouldn't use the heroes instead.")
        case .space:
            XCTFail("A DM shouldn't use a space avatar.")
        case .tombstoned:
            XCTFail("A room shouldn't use the tombstone for its avatar.")
        }
    }
    
    func testDMAvatarNotSet() {
        let details = makeSummary(isDirect: true, hasRoomAvatar: false, isTombstoned: false)
        
        switch details.avatar {
        case .room:
            XCTFail("A DM without an avatar should defer to the hero for the correct placeholder tint colour.")
        case .heroes(let heroes):
            XCTAssertEqual(heroes, self.heroes)
        case .space:
            XCTFail("A DM shouldn't use a space avatar.")
        case .tombstoned:
            XCTFail("A room shouldn't use the tombstone for its avatar.")
        }
    }
    
    func testTombstonedAvatar() {
        let details = makeSummary(isDirect: false, hasRoomAvatar: true, isTombstoned: true)
        
        XCTAssertEqual(details.avatar, .tombstoned)
    }
    
    // MARK: - Helpers
    
    func makeSummary(isDirect: Bool, hasRoomAvatar: Bool, isTombstoned: Bool) -> RoomSummary {
        RoomSummary(room: .init(noPointer: .init()),
                    id: roomDetails.id,
                    joinRequestType: nil,
                    name: roomDetails.name,
                    isDirect: isDirect,
                    avatarURL: hasRoomAvatar ? roomDetails.avatarURL : nil,
                    heroes: heroes,
                    activeMembersCount: 0,
                    lastMessage: nil,
                    lastMessageDate: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: nil,
                    canonicalAlias: nil,
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: isTombstoned)
    }
}
