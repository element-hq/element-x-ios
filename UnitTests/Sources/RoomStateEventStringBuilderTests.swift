//
// Copyright 2023 New Vector Ltd
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

@testable import ElementX
import MatrixRustSDK
import XCTest

class RoomStateEventStringBuilderTests: XCTestCase {
    var userID: String!
    var stringBuilder: RoomStateEventStringBuilder!
    
    override func setUp() {
        userID = "@alice:matrix.org"
        stringBuilder = RoomStateEventStringBuilder(userID: userID)
    }
    
    func testDisplayNameChanges() {
        // Changes by you.
        validateDisplayNameChange(senderID: userID, oldName: "Alice", newName: "Bob",
                                  expectedString: L10n.stateEventDisplayNameChangedFromByYou("Alice", "Bob"))
        validateDisplayNameChange(senderID: userID, oldName: "Alice", newName: nil,
                                  expectedString: L10n.stateEventDisplayNameRemovedByYou("Alice"))
        validateDisplayNameChange(senderID: userID, oldName: nil, newName: "Alice",
                                  expectedString: L10n.stateEventDisplayNameSetByYou("Alice"))
        
        // Changes by someone else.
        let senderID = "@bob:matrix.org"
        validateDisplayNameChange(senderID: senderID, oldName: "Bob", newName: "Alice",
                                  expectedString: L10n.stateEventDisplayNameChangedFrom(senderID, "Bob", "Alice"))
        validateDisplayNameChange(senderID: senderID, oldName: "Bob", newName: nil,
                                  expectedString: L10n.stateEventDisplayNameRemoved(senderID, "Bob"))
        validateDisplayNameChange(senderID: senderID, oldName: nil, newName: "Bob",
                                  expectedString: L10n.stateEventDisplayNameSet(senderID, "Bob"))
    }
    
    func validateDisplayNameChange(senderID: String, oldName: String?, newName: String?, expectedString: String) {
        let sender = TimelineItemSender(id: senderID, displayName: newName)
        let string = stringBuilder.buildProfileChangeString(displayName: newName,
                                                            previousDisplayName: oldName,
                                                            avatarURLString: nil,
                                                            previousAvatarURLString: nil,
                                                            member: sender.id,
                                                            memberIsYou: sender.id == userID)
        XCTAssertEqual(string, expectedString)
    }
    
    func testAvatarChanges() {
        // Changes by you.
        validateAvatarChange(senderID: userID, oldAvatarURL: "mxc://1", newAvatarURL: "mxc://2",
                             expectedString: L10n.stateEventAvatarUrlChangedByYou)
        validateAvatarChange(senderID: userID, oldAvatarURL: "mxc://1", newAvatarURL: nil,
                             expectedString: L10n.stateEventAvatarUrlChangedByYou)
        validateAvatarChange(senderID: userID, oldAvatarURL: nil, newAvatarURL: "mxc://1",
                             expectedString: L10n.stateEventAvatarUrlChangedByYou)
        
        // Changes by someone else.
        let senderID = "@bob:matrix.org"
        let senderName = "Bob"
        validateAvatarChange(senderID: senderID, senderName: senderName, oldAvatarURL: "mxc://1", newAvatarURL: "mxc://2",
                             expectedString: L10n.stateEventAvatarUrlChanged(senderName))
        validateAvatarChange(senderID: senderID, senderName: senderName, oldAvatarURL: "mxc://1", newAvatarURL: nil,
                             expectedString: L10n.stateEventAvatarUrlChanged(senderName))
        validateAvatarChange(senderID: senderID, senderName: senderName, oldAvatarURL: nil, newAvatarURL: "mxc://1",
                             expectedString: L10n.stateEventAvatarUrlChanged(senderName))
    }
    
    func validateAvatarChange(senderID: String, senderName: String? = nil,
                              oldAvatarURL: String?, newAvatarURL: String?,
                              expectedString: String) {
        let sender = TimelineItemSender(id: senderID, displayName: senderName)
        let string = stringBuilder.buildProfileChangeString(displayName: senderName,
                                                            previousDisplayName: senderName,
                                                            avatarURLString: newAvatarURL,
                                                            previousAvatarURLString: oldAvatarURL,
                                                            member: sender.id,
                                                            memberIsYou: sender.id == userID)
        XCTAssertEqual(string, expectedString)
    }
    
    // MARK: - User Power Levels
    
    let aliceID = "@alice"
    let bobID = "@bob"
    
    func testUserPowerLevelsPromotion() {
        var string = stringBuilder.buildString(for: .roomPowerLevels(users: [aliceID: suggestedPowerLevelForRole(role: .moderator)],
                                                                     previous: [aliceID: suggestedPowerLevelForRole(role: .user)]),
                                               sender: TimelineItemSender(id: ""),
                                               isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventPromotedToModerator(aliceID))
        
        string = stringBuilder.buildString(for: .roomPowerLevels(users: [aliceID: suggestedPowerLevelForRole(role: .administrator)],
                                                                 previous: [aliceID: suggestedPowerLevelForRole(role: .user)]),
                                           sender: TimelineItemSender(id: ""),
                                           isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventPromotedToAdministrator(aliceID))
        
        string = stringBuilder.buildString(for: .roomPowerLevels(users: [aliceID: suggestedPowerLevelForRole(role: .administrator)],
                                                                 previous: [aliceID: suggestedPowerLevelForRole(role: .moderator)]),
                                           sender: TimelineItemSender(id: ""),
                                           isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventPromotedToAdministrator(aliceID))
    }
    
    func testUserPowerLevelsDemotion() {
        var string = stringBuilder.buildString(for: .roomPowerLevels(users: [aliceID: suggestedPowerLevelForRole(role: .moderator)],
                                                                     previous: [aliceID: suggestedPowerLevelForRole(role: .administrator)]),
                                               sender: TimelineItemSender(id: ""),
                                               isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventDemotedToModerator(aliceID))
        
        string = stringBuilder.buildString(for: .roomPowerLevels(users: [aliceID: suggestedPowerLevelForRole(role: .user)],
                                                                 previous: [aliceID: suggestedPowerLevelForRole(role: .administrator)]),
                                           sender: TimelineItemSender(id: ""),
                                           isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventDemotedToMember(aliceID))
        
        string = stringBuilder.buildString(for: .roomPowerLevels(users: [aliceID: suggestedPowerLevelForRole(role: .user)],
                                                                 previous: [aliceID: suggestedPowerLevelForRole(role: .moderator)]),
                                           sender: TimelineItemSender(id: ""),
                                           isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventDemotedToMember(aliceID))
    }
    
    func testMultipleUserPowerLevels() {
        let new = [aliceID: suggestedPowerLevelForRole(role: .administrator),
                   bobID: suggestedPowerLevelForRole(role: .user)]
        let previous = [aliceID: suggestedPowerLevelForRole(role: .user),
                        bobID: suggestedPowerLevelForRole(role: .moderator)]
        let string = stringBuilder.buildString(for: .roomPowerLevels(users: new, previous: previous),
                                               sender: TimelineItemSender(id: ""),
                                               isOutgoing: false)
        XCTAssertEqual(string?.contains(L10n.stateEventPromotedToAdministrator(aliceID)), true)
        XCTAssertEqual(string?.contains(L10n.stateEventDemotedToMember(bobID)), true)
    }
    
    func testInvalidUserPowerLevels() {
        // Admin demotions aren't relevant.
        var string = stringBuilder.buildString(for: .roomPowerLevels(users: [aliceID: 100],
                                                                     previous: [aliceID: 200]),
                                               sender: TimelineItemSender(id: ""),
                                               isOutgoing: false)
        XCTAssertNil(string)
        
        // User promotions aren't relevant.
        string = stringBuilder.buildString(for: .roomPowerLevels(users: [aliceID: 0],
                                                                 previous: [aliceID: -100]),
                                           sender: TimelineItemSender(id: ""),
                                           isOutgoing: false)
        XCTAssertNil(string)
        
        // Or more generally, any change within the same role isn't relevant either.
        string = stringBuilder.buildString(for: .roomPowerLevels(users: [aliceID: 75],
                                                                 previous: [aliceID: 60]),
                                           sender: TimelineItemSender(id: ""),
                                           isOutgoing: false)
        XCTAssertNil(string)
        
        let new = [aliceID: 100,
                   bobID: suggestedPowerLevelForRole(role: .user)]
        let previous = [aliceID: 200,
                        bobID: suggestedPowerLevelForRole(role: .moderator)]
        string = stringBuilder.buildString(for: .roomPowerLevels(users: new, previous: previous),
                                           sender: TimelineItemSender(id: ""),
                                           isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventDemotedToMember(bobID))
    }
}
