//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

class RoomSummaryTests: XCTestCase {
    // swiftlint:disable:next large_tuple
    let roomDetails: (id: String, name: String, avatarURL: URL) = ("room_id", "Room Name", "mxc://hs.tld/room/avatar")
    let heroes = [UserProfileProxy(userID: "hero_1", displayName: "Hero 1", avatarURL: "mxc://hs.tld/user/avatar")]
    
    func testRoomAvatar() {
        let details = makeSummary(isDirect: false, isSpace: false, hasRoomAvatar: true, isTombstoned: false)
        
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
        let details = makeSummary(isDirect: true, isSpace: false, hasRoomAvatar: true, isTombstoned: false)
        
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
        let details = makeSummary(isDirect: true, isSpace: false, hasRoomAvatar: false, isTombstoned: false)
        
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
    
    func testSpaceAvatar() {
        let details = makeSummary(isDirect: false, isSpace: true, hasRoomAvatar: true, isTombstoned: false)
        
        switch details.avatar {
        case .room:
            XCTFail("A space shouldn't use a room avatar.")
        case .heroes:
            XCTFail("A room shouldn't use the heroes for its avatar.")
        case .space(let id, let name, let avatarURL):
            XCTAssertEqual(id, roomDetails.id)
            XCTAssertEqual(name, roomDetails.name)
            XCTAssertEqual(avatarURL, roomDetails.avatarURL)
        case .tombstoned:
            XCTFail("A room shouldn't use the tombstone for its avatar.")
        }
    }
    
    func testTombstonedAvatar() {
        let details = makeSummary(isDirect: false, isSpace: false, hasRoomAvatar: true, isTombstoned: true)
        
        XCTAssertEqual(details.avatar, .tombstoned)
    }
    
    // MARK: - Helpers
    
    func makeSummary(isDirect: Bool, isSpace: Bool, hasRoomAvatar: Bool, isTombstoned: Bool) -> RoomSummary {
        RoomSummary(room: .init(noHandle: .init()),
                    id: roomDetails.id,
                    joinRequestType: nil,
                    name: roomDetails.name,
                    isDirect: isDirect,
                    isSpace: isSpace,
                    avatarURL: hasRoomAvatar ? roomDetails.avatarURL : nil,
                    heroes: heroes,
                    activeMembersCount: 0,
                    lastMessage: nil,
                    lastMessageDate: nil,
                    lastMessageState: nil,
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
