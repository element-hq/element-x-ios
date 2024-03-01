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

import Foundation
import MatrixRustSDK

struct RoomPermissionsSetting: Identifiable {
    var id: KeyPath<RoomPermissions, RoomMemberDetails.Role?> { keyPath }
    
    let keyPath: WritableKeyPath<RoomPermissions, RoomMemberDetails.Role?>
    var value: RoomMemberDetails.Role
    let title: String
    
    var allValues: [(title: String, tag: RoomMemberDetails.Role)] {
        [
            (title: L10n.screenRoomChangePermissionsAdministrators, tag: .administrator),
            (title: L10n.screenRoomChangePermissionsModerators, tag: .moderator),
            (title: L10n.screenRoomChangePermissionsEveryone, tag: .user)
        ]
    }
}

struct RoomPermissions {
    /// The level required to ban a user.
    var ban: RoomMemberDetails.Role?
    /// The level required to invite a user.
    var invite: RoomMemberDetails.Role?
    /// The level required to kick a user.
    var kick: RoomMemberDetails.Role?
    /// The level required to redact an event.
    var redact: RoomMemberDetails.Role?
    /// The default level required to send message events.
    var eventsDefault: RoomMemberDetails.Role?
    /// The default level required to send state events.
    var stateDefault: RoomMemberDetails.Role?
    /// The default power level for every user in the room.
    var usersDefault: RoomMemberDetails.Role?
    /// The level required to change the room's name.
    var roomName: RoomMemberDetails.Role?
    /// The level required to change the room's avatar.
    var roomAvatar: RoomMemberDetails.Role?
    /// The level required to change the room's topic.
    var roomTopic: RoomMemberDetails.Role?
}

extension RoomPermissions {
    /// Returns the default value for a particular permission.
    static func defaultValue(for keyPath: KeyPath<RoomPermissions, RoomMemberDetails.Role?>) -> RoomMemberDetails.Role {
        switch keyPath {
        case \.ban: .moderator
        case \.invite: .user
        case \.kick: .moderator
        case \.redact: .moderator
        case \.eventsDefault: .user
        case \.stateDefault: .moderator
        case \.usersDefault: .user
        case \.roomName: .moderator
        case \.roomAvatar: .moderator
        case \.roomTopic: .moderator
        default: fatalError("Unexpected key path: \(keyPath)")
        }
    }
    
    /// Constructs a set of permissions using the default values.
    static var `default`: RoomPermissions {
        RoomPermissions(ban: defaultValue(for: \.ban),
                        invite: defaultValue(for: \.invite),
                        kick: defaultValue(for: \.kick),
                        redact: defaultValue(for: \.redact),
                        eventsDefault: defaultValue(for: \.eventsDefault),
                        stateDefault: defaultValue(for: \.stateDefault),
                        usersDefault: defaultValue(for: \.usersDefault),
                        roomName: defaultValue(for: \.roomName),
                        roomAvatar: defaultValue(for: \.roomAvatar),
                        roomTopic: defaultValue(for: \.roomTopic))
    }
    
    init(powerLevelChanges: RoomPowerLevelChanges) {
        ban = powerLevelChanges.ban.map(RoomMemberDetails.Role.init)
        invite = powerLevelChanges.invite.map(RoomMemberDetails.Role.init)
        kick = powerLevelChanges.kick.map(RoomMemberDetails.Role.init)
        redact = powerLevelChanges.redact.map(RoomMemberDetails.Role.init)
        eventsDefault = powerLevelChanges.eventsDefault.map(RoomMemberDetails.Role.init)
        stateDefault = powerLevelChanges.stateDefault.map(RoomMemberDetails.Role.init)
        usersDefault = powerLevelChanges.usersDefault.map(RoomMemberDetails.Role.init)
        roomName = powerLevelChanges.roomName.map(RoomMemberDetails.Role.init)
        roomAvatar = powerLevelChanges.roomAvatar.map(RoomMemberDetails.Role.init)
        roomTopic = powerLevelChanges.roomTopic.map(RoomMemberDetails.Role.init)
    }
    
    func makePowerLevelChanges() -> RoomPowerLevelChanges {
        RoomPowerLevelChanges(ban: ban?.rustPowerLevel,
                              invite: invite?.rustPowerLevel,
                              kick: kick?.rustPowerLevel,
                              redact: redact?.rustPowerLevel,
                              eventsDefault: eventsDefault?.rustPowerLevel,
                              stateDefault: stateDefault?.rustPowerLevel,
                              usersDefault: usersDefault?.rustPowerLevel,
                              roomName: roomName?.rustPowerLevel,
                              roomAvatar: roomAvatar?.rustPowerLevel,
                              roomTopic: roomTopic?.rustPowerLevel)
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
