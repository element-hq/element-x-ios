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
        bindings.settings.contains { currentPermissions[keyPath: $0.keyPath] != $0.value }
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
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsRoomName,
                                       value: currentPermissions.roomName,
                                       keyPath: \.roomName),
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsRoomAvatar,
                                       value: currentPermissions.roomAvatar,
                                       keyPath: \.roomAvatar),
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsRoomTopic,
                                       value: currentPermissions.roomTopic,
                                       keyPath: \.roomTopic)
            ]
            
            self.init(title: L10n.screenRoomChangePermissionsRoomDetails, currentPermissions: currentPermissions, bindings: .init(settings: settings))
        
        case .messagesAndContent:
            let settings = [
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsSendMessages,
                                       value: currentPermissions.eventsDefault,
                                       keyPath: \.eventsDefault),
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsDeleteMessages,
                                       value: currentPermissions.redact,
                                       keyPath: \.redact)
            ]
            
            self.init(title: L10n.screenRoomChangePermissionsMessagesAndContent, currentPermissions: currentPermissions, bindings: .init(settings: settings))
        
        case .memberModeration:
            let settings = [
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsInvitePeople,
                                       value: currentPermissions.invite,
                                       keyPath: \.invite),
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsRemovePeople,
                                       value: currentPermissions.kick,
                                       keyPath: \.kick),
                RoomPermissionsSetting(title: L10n.screenRoomChangePermissionsBanPeople,
                                       value: currentPermissions.ban,
                                       keyPath: \.ban)
            ]
            
            self.init(title: L10n.screenRoomChangePermissionsMemberModeration, currentPermissions: currentPermissions, bindings: .init(settings: settings))
        }
    }
}
