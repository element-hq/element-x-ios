//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import MatrixRustSDK
import XCTest

@testable import ElementX

class RoomPermissionsTests: XCTestCase {
    func testFromRust() {
        // Given a set of power level changes with various values.
        let powerLevels = RoomPowerLevels(ban: 100,
                                          invite: 100,
                                          kick: 100,
                                          redact: 50,
                                          eventsDefault: 50,
                                          stateDefault: 50,
                                          usersDefault: 0,
                                          roomName: 0,
                                          roomAvatar: 0,
                                          roomTopic: 0)
        
        // When creating room permissions from them.
        let permissions = RoomPermissions(powerLevels: powerLevels)
        
        // Then the permissions should be created with values mapped to the correct role.
        XCTAssertEqual(permissions.ban, .administrator)
        XCTAssertEqual(permissions.invite, .administrator)
        XCTAssertEqual(permissions.kick, .administrator)
        XCTAssertEqual(permissions.redact, .moderator)
        XCTAssertEqual(permissions.eventsDefault, .moderator)
        XCTAssertEqual(permissions.stateDefault, .moderator)
        XCTAssertEqual(permissions.usersDefault, .user)
        XCTAssertEqual(permissions.roomName, .user)
        XCTAssertEqual(permissions.roomAvatar, .user)
        XCTAssertEqual(permissions.roomTopic, .user)
    }
}
