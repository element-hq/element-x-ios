//
// Copyright 2022 New Vector Ltd
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

enum RoomChangePermissionsScreenViewModelAction {
    case cancel
}

struct RoomChangePermissionsScreenViewState: BindableState {
    /// The screen's title.
    let title: String
    /// The current permissions that are set on the room.
    var currentPermissions: RoomPermissions
    
    var bindings: RoomChangePermissionsScreenViewStateBindings
    
    /// Whether or not there are and changes to be saved.
    var hasChanges: Bool {
        bindings.settings.contains { currentPermissions[keyPath: $0.keyPath] ?? RoomPermissions.defaultValue(for: $0.keyPath) != $0.value }
    }
}

struct RoomChangePermissionsScreenViewStateBindings: BindableState {
    /// All of the settings shown for this screen.
    var settings: [RoomPermissionsSetting]
    /// Information about the currently displayed alert.
    var alertInfo: AlertInfo<RoomChangePermissionsScreenAlertType>?
}

enum RoomChangePermissionsScreenAlertType {
    /// The generic error message.
    case generic
}

enum RoomChangePermissionsScreenViewAction {
    /// Save the permissions.
    case save
}

extension RoomChangePermissionsScreenViewState {
    /// Creates a view state for a particular group of permissions.
    /// - Parameters:
    ///   - currentPermissions: The current permissions for the room.
    ///   - group: The group of permissions that should be shown in the screen.
    init(currentPermissions: RoomPermissions, group: RoomRolesAndPermissionsScreenPermissionsGroup) {
        switch group {
        case .roomDetails:
            let settings = [
                RoomPermissionsSetting(keyPath: \.roomName,
                                       value: currentPermissions.roomName ?? RoomPermissions.defaultValue(for: \.roomName),
                                       title: L10n.screenRoomChangePermissionsRoomName),
                RoomPermissionsSetting(keyPath: \.roomAvatar,
                                       value: currentPermissions.roomAvatar ?? RoomPermissions.defaultValue(for: \.roomAvatar),
                                       title: L10n.screenRoomChangePermissionsRoomAvatar),
                RoomPermissionsSetting(keyPath: \.roomTopic,
                                       value: currentPermissions.roomTopic ?? RoomPermissions.defaultValue(for: \.roomTopic),
                                       title: L10n.screenRoomChangePermissionsRoomTopic)
            ]
            
            self.init(title: L10n.screenRoomChangePermissionsRoomDetails, currentPermissions: currentPermissions, bindings: .init(settings: settings))
        
        case .messagesAndContent:
            let settings = [
                RoomPermissionsSetting(keyPath: \.eventsDefault,
                                       value: currentPermissions.eventsDefault ?? RoomPermissions.defaultValue(for: \.eventsDefault),
                                       title: L10n.screenRoomChangePermissionsSendMessages),
                RoomPermissionsSetting(keyPath: \.redact,
                                       value: currentPermissions.redact ?? RoomPermissions.defaultValue(for: \.redact),
                                       title: L10n.screenRoomChangePermissionsDeleteMessages)
            ]
            
            self.init(title: L10n.screenRoomChangePermissionsMessagesAndContent, currentPermissions: currentPermissions, bindings: .init(settings: settings))
        
        case .memberModeration:
            let settings = [
                RoomPermissionsSetting(keyPath: \.invite,
                                       value: currentPermissions.invite ?? RoomPermissions.defaultValue(for: \.invite),
                                       title: L10n.screenRoomChangePermissionsInvitePeople),
                RoomPermissionsSetting(keyPath: \.kick,
                                       value: currentPermissions.kick ?? RoomPermissions.defaultValue(for: \.kick),
                                       title: L10n.screenRoomChangePermissionsRemovePeople),
                RoomPermissionsSetting(keyPath: \.ban,
                                       value: currentPermissions.ban ?? RoomPermissions.defaultValue(for: \.ban),
                                       title: L10n.screenRoomChangePermissionsBanPeople)
            ]
            
            self.init(title: L10n.screenRoomChangePermissionsMemberModeration, currentPermissions: currentPermissions, bindings: .init(settings: settings))
        }
    }
}
