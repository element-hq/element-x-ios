//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct RoomPermissionsSetting: Identifiable {
    static let allValues: [(title: String, tag: RoomRole)] = [(title: L10n.screenRoomChangePermissionsAdministrators, tag: .administrator),
                                                              (title: L10n.screenRoomChangePermissionsModerators, tag: .moderator),
                                                              (title: L10n.screenRoomChangePermissionsEveryone, tag: .user)]
    var id: KeyPath<RoomPermissions, Int64> { keyPath }
    
    /// The title of this setting.
    let title: String
    
    /// The selected role of this setting.
    var value: Int64
    
    let ownPowerLevel: RoomPowerLevel
    
    var roleValue: RoomRole {
        get {
            RoomRole(powerLevelValue: value)
        } set {
            value = newValue.powerLevelValue
        }
    }
        
    /// The `RoomPermissions` property that this setting is for.
    let keyPath: KeyPath<RoomPermissions, Int64>
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
        case \.spaceChild: \.spaceChild
        default: fatalError("Unexpected key path: \(keyPath)")
        }
    }
    
    /// Can the setting be edited
    var isDisabled: Bool {
        switch ownPowerLevel {
        case .value(let ownValue):
            ownValue < value
        case .infinite:
            false
        }
    }
    
    /// All of the available roles that this setting can be configured with.
    var availableValues: [(title: String, tag: RoomRole)] {
        if isDisabled {
            Self.allValues.filter { $0.tag == RoomRole(powerLevelValue: value) }
        } else {
            Self.allValues.filter { $0.tag <= ownPowerLevel.role }
        }
    }
    
    init(title: String,
         value: Int64,
         ownPowerLevel: RoomPowerLevel,
         keyPath: KeyPath<RoomPermissions, Int64>) {
        self.ownPowerLevel = ownPowerLevel
        self.title = title
        self.value = value
        self.keyPath = keyPath
    }
}

struct RoomPermissions {
    /// The level required to ban a user.
    var ban: Int64
    /// The level required to invite a user.
    var invite: Int64
    /// The level required to kick a user.
    var kick: Int64
    /// The level required to redact an event.
    var redact: Int64
    /// The default level required to send message events.
    var eventsDefault: Int64
    /// The default level required to send state events.
    var stateDefault: Int64
    /// The default power level for every user in the room.
    var usersDefault: Int64
    /// The level required to change the room's name.
    var roomName: Int64
    /// The level required to change the room's avatar.
    var roomAvatar: Int64
    /// The level required to change the room's topic.
    var roomTopic: Int64
    /// The level required to add/remove childrens from a space.
    var spaceChild: Int64
}

extension RoomPermissions {
    /// Create permissions from the room's power levels.
    init(powerLevels: RoomPowerLevelsValues) {
        ban = powerLevels.ban
        invite = powerLevels.invite
        kick = powerLevels.kick
        redact = powerLevels.redact
        eventsDefault = powerLevels.eventsDefault
        stateDefault = powerLevels.stateDefault
        usersDefault = powerLevels.usersDefault
        roomName = powerLevels.roomName
        roomAvatar = powerLevels.roomAvatar
        roomTopic = powerLevels.roomTopic
        spaceChild = powerLevels.spaceChild
    }
}
