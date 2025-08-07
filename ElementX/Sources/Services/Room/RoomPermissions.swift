//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RoomPermissionsSetting: Identifiable {
    var id: KeyPath<RoomPermissions, RoomRole> { keyPath }
    
    /// The title of this setting.
    let title: String
    
    /// The selected role of this setting.
    var value: RoomRole
    /// All of the available roles that this setting can be configured with.
    var allValues: [(title: String, tag: RoomRole)] {
        [
            (title: L10n.screenRoomChangePermissionsAdministrators, tag: .administrator),
            (title: L10n.screenRoomChangePermissionsModerators, tag: .moderator),
            (title: L10n.screenRoomChangePermissionsEveryone, tag: .user)
        ]
    }
    
    /// The `RoomPermissions` property that this setting is for.
    let keyPath: KeyPath<RoomPermissions, RoomRole>
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
    var ban: RoomRole
    /// The level required to invite a user.
    var invite: RoomRole
    /// The level required to kick a user.
    var kick: RoomRole
    /// The level required to redact an event.
    var redact: RoomRole
    /// The default level required to send message events.
    var eventsDefault: RoomRole
    /// The default level required to send state events.
    var stateDefault: RoomRole
    /// The default power level for every user in the room.
    var usersDefault: RoomRole
    /// The level required to change the room's name.
    var roomName: RoomRole
    /// The level required to change the room's avatar.
    var roomAvatar: RoomRole
    /// The level required to change the room's topic.
    var roomTopic: RoomRole
}

extension RoomPermissions {
    /// Create permissions from the room's power levels.
    init(powerLevels: RoomPowerLevelsValues) {
        ban = RoomRole(powerLevelValue: powerLevels.ban)
        invite = RoomRole(powerLevelValue: powerLevels.invite)
        kick = RoomRole(powerLevelValue: powerLevels.kick)
        redact = RoomRole(powerLevelValue: powerLevels.redact)
        eventsDefault = RoomRole(powerLevelValue: powerLevels.eventsDefault)
        stateDefault = RoomRole(powerLevelValue: powerLevels.stateDefault)
        usersDefault = RoomRole(powerLevelValue: powerLevels.usersDefault)
        roomName = RoomRole(powerLevelValue: powerLevels.roomName)
        roomAvatar = RoomRole(powerLevelValue: powerLevels.roomAvatar)
        roomTopic = RoomRole(powerLevelValue: powerLevels.roomTopic)
    }
}
