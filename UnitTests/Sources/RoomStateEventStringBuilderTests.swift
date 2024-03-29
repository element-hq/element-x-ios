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
}
