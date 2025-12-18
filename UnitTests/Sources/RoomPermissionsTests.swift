//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
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
                                                spaceChild: 100)
        
        // When creating room permissions from them.
        let permissions = RoomPermissions(powerLevels: powerLevels)
        
        // Then the permissions should be created with values mapped to the correct role.
        XCTAssertEqual(permissions.ban, RoomRole.administrator.powerLevelValue)
        XCTAssertEqual(permissions.invite, RoomRole.administrator.powerLevelValue)
        XCTAssertEqual(permissions.kick, RoomRole.administrator.powerLevelValue)
        XCTAssertEqual(permissions.redact, RoomRole.moderator.powerLevelValue)
        XCTAssertEqual(permissions.eventsDefault, RoomRole.moderator.powerLevelValue)
        XCTAssertEqual(permissions.stateDefault, RoomRole.moderator.powerLevelValue)
        XCTAssertEqual(permissions.usersDefault, RoomRole.user.powerLevelValue)
        XCTAssertEqual(permissions.roomName, RoomRole.user.powerLevelValue)
        XCTAssertEqual(permissions.roomAvatar, RoomRole.user.powerLevelValue)
        XCTAssertEqual(permissions.roomTopic, RoomRole.user.powerLevelValue)
        XCTAssertEqual(permissions.spaceChild, RoomRole.administrator.powerLevelValue)
    }
}
