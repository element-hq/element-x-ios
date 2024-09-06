//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    init(powerLevels: RoomPowerLevels) {
        ban = RoomMemberDetails.Role(rustPowerLevel: powerLevels.ban)
        invite = RoomMemberDetails.Role(rustPowerLevel: powerLevels.invite)
        kick = RoomMemberDetails.Role(rustPowerLevel: powerLevels.kick)
        redact = RoomMemberDetails.Role(rustPowerLevel: powerLevels.redact)
        eventsDefault = RoomMemberDetails.Role(rustPowerLevel: powerLevels.eventsDefault)
        stateDefault = RoomMemberDetails.Role(rustPowerLevel: powerLevels.stateDefault)
        usersDefault = RoomMemberDetails.Role(rustPowerLevel: powerLevels.usersDefault)
        roomName = RoomMemberDetails.Role(rustPowerLevel: powerLevels.roomName)
        roomAvatar = RoomMemberDetails.Role(rustPowerLevel: powerLevels.roomAvatar)
        roomTopic = RoomMemberDetails.Role(rustPowerLevel: powerLevels.roomTopic)
    }
}

extension RoomMemberDetails.Role {
    init(rustPowerLevel: Int64) {
        self.init(suggestedRoleForPowerLevel(powerLevel: rustPowerLevel))
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
    
    var rustPowerLevel: Int64 {
        suggestedPowerLevelForRole(role: rustRole)
    }
}

extension RoomPowerLevels {
    static var mock: RoomPowerLevels {
        RoomPowerLevels(ban: 50,
                        invite: 0,
                        kick: 50,
                        redact: 50,
                        eventsDefault: 0,
                        stateDefault: 50,
                        usersDefault: 0,
                        roomName: 50,
                        roomAvatar: 50,
                        roomTopic: 50)
    }
}
