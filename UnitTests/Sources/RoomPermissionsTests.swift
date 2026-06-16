//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import XCTest

@testable import ElementX

class RoomPermissionsTests: XCTestCase {
    func testFromRust() {
        // Given a set of power level changes with various values.
        let powerLevels = RoomPowerLevelsValues(ban: 100,
                                                invite: 100,
                                                kick: 100,
                                                redact: 50,
                                                eventsDefault: 50,
                                                stateDefault: 50,
                                                usersDefault: 0,
                                                roomName: 0,
                                                roomAvatar: 0,
                                                roomTopic: 0,
                                                spaceChild: 50,
                                                beacon: 0,
                                                beaconInfo: 50)
        
        // When creating room permissions from them.
        let permissions = RoomPermissions(powerLevels: powerLevels)
        
        // Then the permissions should be created with values mapped to the correct role.
        XCTAssertEqual(permissions.ban, RoomRole.administrator)
        XCTAssertEqual(permissions.invite, RoomRole.administrator)
        XCTAssertEqual(permissions.kick, RoomRole.administrator)
        XCTAssertEqual(permissions.redact, RoomRole.moderator)
        XCTAssertEqual(permissions.eventsDefault, RoomRole.moderator)
        XCTAssertEqual(permissions.stateDefault, RoomRole.moderator)
        XCTAssertEqual(permissions.usersDefault, RoomRole.user)
        XCTAssertEqual(permissions.roomName, RoomRole.user)
        XCTAssertEqual(permissions.roomAvatar, RoomRole.user)
        XCTAssertEqual(permissions.roomTopic, RoomRole.user)
    }
}
