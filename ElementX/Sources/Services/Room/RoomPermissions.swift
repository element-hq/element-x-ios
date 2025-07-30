//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RoomPermissionsSetting: Identifiable {
    var id: KeyPath<RoomPermissions, RoomMemberDetails.Role> { keyPath }
    
    /// The title of this setting.
    let title: String
    
    /// The selected role of this setting.
    var value: RoomMemberDetails.Role
    /// All of the available roles that this setting can be configured with.
    var allValues: [(title: String, tag: RoomMemberDetails.Role)] {
        [
            (title: L10n.screenRoomChangePermissionsAdministrators, tag: .administrator),
            (title: L10n.screenRoomChangePermissionsModerators, tag: .moderator),
            (title: L10n.screenRoomChangePermissionsEveryone, tag: .user)
        ]
    }
    
    /// The `RoomPermissions` property that this setting is for.
    let keyPath: KeyPath<RoomPermissions, RoomMemberDetails.Role>
    /// The `RoomPowerLevelChanges` property that this setting is saved into.
    var rustKeyPath: WritableKeyPath<RoomPowerLevelChanges, Int64?> {
        switch keyPath {
        case \.ban: \.ban
        case \.invite: \.invite
        case \.kick: \.kick
        case \.redact: \.redact
        case \.eventsDefault: \.eventsDefault
        case \.stateDefault: \.stateDefault
        case \.usersDefault: \.usersDefault
        case \.roomName: \.roomName
        case \.roomAvatar: \.roomAvatar
        case \.roomTopic: \.roomTopic
        default: fatalError("Unexpected key path: \(keyPath)")
        }
    }
}

struct RoomPermissions {
    /// The level required to ban a user.
    var ban: RoomMemberDetails.Role
    /// The level required to invite a user.
    var invite: RoomMemberDetails.Role
    /// The level required to kick a user.
    var kick: RoomMemberDetails.Role
    /// The level required to redact an event.
    var redact: RoomMemberDetails.Role
    /// The default level required to send message events.
    var eventsDefault: RoomMemberDetails.Role
    /// The default level required to send state events.
    var stateDefault: RoomMemberDetails.Role
    /// The default power level for every user in the room.
    var usersDefault: RoomMemberDetails.Role
    /// The level required to change the room's name.
    var roomName: RoomMemberDetails.Role
    /// The level required to change the room's avatar.
    var roomAvatar: RoomMemberDetails.Role
    /// The level required to change the room's topic.
    var roomTopic: RoomMemberDetails.Role
}

extension RoomPermissions {
    /// Create permissions from the room's power levels.
    init(powerLevels: RoomPowerLevelsValues) {
        ban = RoomMemberDetails.Role(powerLevelValue: powerLevels.ban)
        invite = RoomMemberDetails.Role(powerLevelValue: powerLevels.invite)
        kick = RoomMemberDetails.Role(powerLevelValue: powerLevels.kick)
        redact = RoomMemberDetails.Role(powerLevelValue: powerLevels.redact)
        eventsDefault = RoomMemberDetails.Role(powerLevelValue: powerLevels.eventsDefault)
        stateDefault = RoomMemberDetails.Role(powerLevelValue: powerLevels.stateDefault)
        usersDefault = RoomMemberDetails.Role(powerLevelValue: powerLevels.usersDefault)
        roomName = RoomMemberDetails.Role(powerLevelValue: powerLevels.roomName)
        roomAvatar = RoomMemberDetails.Role(powerLevelValue: powerLevels.roomAvatar)
        roomTopic = RoomMemberDetails.Role(powerLevelValue: powerLevels.roomTopic)
    }
}

extension RoomMemberDetails.Role {
    init(powerLevelValue: Int64) {
        do {
            try self.init(suggestedRoleForPowerLevel(powerLevel: .value(value: powerLevelValue)))
        } catch {
            MXLog.error("Falied to convert power level value to role: \(error)")
            self.init(.user)
        }
    }
    
    var rustRole: RoomMemberRole {
        switch self {
        case .administrator:
            .administrator
        case .moderator:
            .moderator
        case .user:
            .user
        }
    }
    
    /// To be used when setting the power level of a user to get the suggested equivalent power level value for that specific role
    /// NOTE: Do not use for comparison, use the true power level instead.
    var powerLevelValue: Int64 {
        do {
            switch try suggestedPowerLevelForRole(role: rustRole) {
            case .infinite:
                // Would be better if the SDK would return this, maybe a `suggestedPowerLevelValueForRole` function would solve the problem
                return 150
            case .value(let value):
                return value
            }
        } catch {
            MXLog.error("Falied to convert role to power level value: \(error)")
            return 0
        }
    }
}
