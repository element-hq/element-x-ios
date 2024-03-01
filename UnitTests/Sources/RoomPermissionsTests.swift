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

import MatrixRustSDK
import XCTest

@testable import ElementX

class RoomPermissionsTests: XCTestCase {
    func testEmptyFromRust() {
        // Given an empty set of power level changes.
        let powerLevelChanges = RoomPowerLevelChanges()
        
        // When creating room permissions from them.
        let permissions = RoomPermissions(powerLevelChanges: powerLevelChanges)
        
        // Then none of the permissions should be set.
        XCTAssertNil(permissions.ban)
        XCTAssertNil(permissions.invite)
        XCTAssertNil(permissions.kick)
        XCTAssertNil(permissions.redact)
        XCTAssertNil(permissions.eventsDefault)
        XCTAssertNil(permissions.stateDefault)
        XCTAssertNil(permissions.usersDefault)
        XCTAssertNil(permissions.roomName)
        XCTAssertNil(permissions.roomAvatar)
        XCTAssertNil(permissions.roomTopic)
    }
    
    func testCompleteFromRust() {
        // Given a set of power level changes with all the values set to 100.
        let powerLevelChanges = RoomPowerLevelChanges(ban: 100,
                                                      invite: 100,
                                                      kick: 100,
                                                      redact: 100,
                                                      eventsDefault: 100,
                                                      stateDefault: 100,
                                                      usersDefault: 100,
                                                      roomName: 100,
                                                      roomAvatar: 100,
                                                      roomTopic: 100)
        
        // When creating room permissions from them.
        let permissions = RoomPermissions(powerLevelChanges: powerLevelChanges)
        
        // Then all of the permissions should be for an administrator.
        XCTAssertEqual(permissions.ban, .administrator)
        XCTAssertEqual(permissions.invite, .administrator)
        XCTAssertEqual(permissions.kick, .administrator)
        XCTAssertEqual(permissions.redact, .administrator)
        XCTAssertEqual(permissions.eventsDefault, .administrator)
        XCTAssertEqual(permissions.stateDefault, .administrator)
        XCTAssertEqual(permissions.usersDefault, .administrator)
        XCTAssertEqual(permissions.roomName, .administrator)
        XCTAssertEqual(permissions.roomAvatar, .administrator)
        XCTAssertEqual(permissions.roomTopic, .administrator)
    }
    
    func testToRust() {
        // Given a set of permissions where on some of the values have been set.
        let permissions = RoomPermissions(roomName: .administrator, roomAvatar: .administrator, roomTopic: .administrator)
        
        // When creating power level changes from them.
        let powerLevelChanges = permissions.makePowerLevelChanges()
        
        // Then only the permissions that were set should be included.
        XCTAssertNil(powerLevelChanges.ban, "Unset values should be nil for Rust to merge with the current value.")
        XCTAssertNil(powerLevelChanges.invite, "Unset values should be nil for Rust to merge with the current value.")
        XCTAssertNil(powerLevelChanges.kick, "Unset values should be nil for Rust to merge with the current value.")
        XCTAssertNil(powerLevelChanges.redact, "Unset values should be nil for Rust to merge with the current value.")
        XCTAssertNil(powerLevelChanges.eventsDefault, "Unset values should be nil for Rust to merge with the current value.")
        XCTAssertNil(powerLevelChanges.stateDefault, "Unset values should be nil for Rust to merge with the current value.")
        XCTAssertNil(powerLevelChanges.usersDefault, "Unset values should be nil for Rust to merge with the current value.")
        XCTAssertEqual(powerLevelChanges.roomName, 100)
        XCTAssertEqual(powerLevelChanges.roomAvatar, 100)
        XCTAssertEqual(powerLevelChanges.roomTopic, 100)
    }
}
