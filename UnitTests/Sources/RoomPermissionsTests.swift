//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import Testing

@Suite
struct RoomPermissionsTests {
    @Test
    func fromRust() {
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
        #expect(permissions.ban == RoomRole.administrator.powerLevelValue)
        #expect(permissions.invite == RoomRole.administrator.powerLevelValue)
        #expect(permissions.kick == RoomRole.administrator.powerLevelValue)
        #expect(permissions.redact == RoomRole.moderator.powerLevelValue)
        #expect(permissions.eventsDefault == RoomRole.moderator.powerLevelValue)
        #expect(permissions.stateDefault == RoomRole.moderator.powerLevelValue)
        #expect(permissions.usersDefault == RoomRole.user.powerLevelValue)
        #expect(permissions.roomName == RoomRole.user.powerLevelValue)
        #expect(permissions.roomAvatar == RoomRole.user.powerLevelValue)
        #expect(permissions.roomTopic == RoomRole.user.powerLevelValue)
        #expect(permissions.spaceChild == RoomRole.administrator.powerLevelValue)
    }
}
