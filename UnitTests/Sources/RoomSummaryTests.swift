//
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest

@testable import ElementX

class RoomSummaryTests: XCTestCase {
    // swiftlint:disable:next large_tuple
    let roomDetails: (id: String, name: String, avatarURL: URL) = ("room_id", "Room Name", "mxc://hs.tld/room/avatar")
    let heroes = [UserProfileProxy(userID: "hero_1", displayName: "Hero 1", avatarURL: "mxc://hs.tld/user/avatar")]
    
    func testRoomAvatar() {
        let details = makeDetails(isDirect: false, hasRoomAvatar: true)
        
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
        let details = makeDetails(isDirect: true, hasRoomAvatar: true)
        
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
        let details = makeDetails(isDirect: true, hasRoomAvatar: false)
        
        switch details.avatar {
        case .room:
            XCTFail("A DM without an avatar should defer to the hero for the correct placeholder tint colour.")
        case .heroes(let heroes):
            XCTAssertEqual(heroes, self.heroes)
        }
    }
    
    // MARK: - Helpers
    
    func makeDetails(isDirect: Bool, hasRoomAvatar: Bool) -> RoomSummary {
        RoomSummary(id: roomDetails.id,
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
