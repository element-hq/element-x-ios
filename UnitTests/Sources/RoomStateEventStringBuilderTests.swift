//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
    
    // MARK: - User Profiles
    
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
    
    // MARK: - Room Info
    
    func testTopicChanges() {
        let you = TimelineItemSender(id: userID, displayName: "Alice")
        let other = TimelineItemSender(id: "@bob:matrix.org", displayName: "Bob")
        
        let newTopic = "New topic"
        var string = stringBuilder.buildString(for: .roomTopic(topic: newTopic), sender: you, isOutgoing: true)
        XCTAssertEqual(string, L10n.stateEventRoomTopicChangedByYou(newTopic))
        string = stringBuilder.buildString(for: .roomTopic(topic: newTopic), sender: other, isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventRoomTopicChanged(other.displayName ?? "", newTopic))
        
        let emptyTopic = ""
        string = stringBuilder.buildString(for: .roomTopic(topic: emptyTopic), sender: you, isOutgoing: true)
        XCTAssertEqual(string, L10n.stateEventRoomTopicRemovedByYou)
        string = stringBuilder.buildString(for: .roomTopic(topic: emptyTopic), sender: other, isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventRoomTopicRemoved(other.displayName ?? ""))
        
        string = stringBuilder.buildString(for: .roomTopic(topic: nil), sender: you, isOutgoing: true)
        XCTAssertEqual(string, L10n.stateEventRoomTopicRemovedByYou)
        string = stringBuilder.buildString(for: .roomTopic(topic: nil), sender: other, isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventRoomTopicRemoved(other.displayName ?? ""))
    }
    
    // MARK: - Room Membership
    
    func testKickMember() {
        let you = TimelineItemSender(id: userID, displayName: "Alice")
        let other = TimelineItemSender(id: "@bob:matrix.org", displayName: "Bob")
        let banned = TimelineItemSender(id: "@spam:matrix.org", displayName: "I like spam")
        
        let reason = "Spam"
        var string = stringBuilder.buildString(for: .kicked,
                                               reason: reason,
                                               memberUserID: banned.id,
                                               memberDisplayName: banned.displayName,
                                               sender: you,
                                               isOutgoing: true)
        XCTAssertEqual(string, L10n.stateEventRoomRemoveByYouWithReason(banned.displayName ?? banned.id, reason))
        string = stringBuilder.buildString(for: .kicked,
                                           reason: nil,
                                           memberUserID: banned.id,
                                           memberDisplayName: banned.displayName,
                                           sender: you,
                                           isOutgoing: true)
        XCTAssertEqual(string, L10n.stateEventRoomRemoveByYou(banned.displayName ?? banned.id))
        string = stringBuilder.buildString(for: .kicked,
                                           reason: reason,
                                           memberUserID: banned.id,
                                           memberDisplayName: banned.displayName,
                                           sender: other,
                                           isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventRoomRemoveWithReason(other.displayName ?? other.id, banned.displayName ?? banned.id, reason))
        string = stringBuilder.buildString(for: .kicked,
                                           reason: nil,
                                           memberUserID: banned.id,
                                           memberDisplayName: banned.displayName,
                                           sender: other,
                                           isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventRoomRemove(other.displayName ?? other.id, banned.displayName ?? banned.id))
    }
    
    func testBanMember() {
        let you = TimelineItemSender(id: userID, displayName: "Alice")
        let other = TimelineItemSender(id: "@bob:matrix.org", displayName: "Bob")
        let banned = TimelineItemSender(id: "@spam:matrix.org", displayName: "I like spam")
        
        let reason = "Spam"
        var string = stringBuilder.buildString(for: .banned,
                                               reason: reason,
                                               memberUserID: banned.id,
                                               memberDisplayName: banned.displayName,
                                               sender: you,
                                               isOutgoing: true)
        XCTAssertEqual(string, L10n.stateEventRoomBanByYouWithReason(banned.displayName ?? banned.id, reason))
        string = stringBuilder.buildString(for: .banned,
                                           reason: nil,
                                           memberUserID: banned.id,
                                           memberDisplayName: banned.displayName,
                                           sender: you,
                                           isOutgoing: true)
        XCTAssertEqual(string, L10n.stateEventRoomBanByYou(banned.displayName ?? banned.id))
        string = stringBuilder.buildString(for: .banned,
                                           reason: reason,
                                           memberUserID: banned.id,
                                           memberDisplayName: banned.displayName,
                                           sender: other,
                                           isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventRoomBanWithReason(other.displayName ?? other.id, banned.displayName ?? banned.id, reason))
        string = stringBuilder.buildString(for: .banned,
                                           reason: nil,
                                           memberUserID: banned.id,
                                           memberDisplayName: banned.displayName,
                                           sender: other,
                                           isOutgoing: false)
        XCTAssertEqual(string, L10n.stateEventRoomBan(other.displayName ?? other.id, banned.displayName ?? banned.id))
    }
}
