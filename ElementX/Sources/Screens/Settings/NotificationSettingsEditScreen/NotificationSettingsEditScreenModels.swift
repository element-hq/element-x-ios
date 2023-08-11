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

enum NotificationSettingsEditScreenViewModelAction {
    case requestRoomNotificationSettingsPresentation(roomID: String)
}

enum NotificationSettingsEditScreenDefaultMode {
    case allMessages
    case mentionsAndKeywordsOnly
}

struct NotificationSettingsEditScreenViewState: BindableState {
    var bindings: NotificationSettingsEditScreenViewStateBindings
    var strings: NotificationSettingsEditScreenStrings
    var isDirect: Bool
    var availableDefaultModes: [NotificationSettingsEditScreenDefaultMode] = [.allMessages, .mentionsAndKeywordsOnly]
    var defaultMode: NotificationSettingsEditScreenDefaultMode?
    var pendingMode: NotificationSettingsEditScreenDefaultMode?
    var roomsWithUserDefinedMode: [NotificationSettingsEditScreenRoom] = []

    func isSelected(mode: NotificationSettingsEditScreenDefaultMode) -> Bool {
        pendingMode == nil && defaultMode == mode
    }
    
    var displayRoomsWithCustomSettings: Bool {
        !roomsWithUserDefinedMode.isEmpty
    }
}

struct NotificationSettingsEditScreenViewStateBindings {
    var searchQuery = ""
    var alertInfo: AlertInfo<NotificationSettingsEditScreenErrorType>?
}

enum NotificationSettingsEditScreenViewAction {
    case setMode(NotificationSettingsEditScreenDefaultMode)
    case selectRoom(roomIdentifier: String)
}

enum NotificationSettingsEditScreenErrorType: Hashable {
    case setModeFailed
}

struct NotificationSettingsEditScreenStrings {
    let navigationTitle: String
    let modeSectionTitle: String
    
    init(isDirect: Bool) {
        if isDirect {
            navigationTitle = L10n.screenNotificationSettingsDirectChats
            modeSectionTitle = L10n.screenNotificationSettingsEditScreenDirectSectionHeader
        } else {
            navigationTitle = L10n.screenNotificationSettingsGroupChats
            modeSectionTitle = L10n.screenNotificationSettingsEditScreenGroupSectionHeader
        }
    }
    
    func string(for mode: NotificationSettingsEditScreenDefaultMode) -> String {
        switch mode {
        case .allMessages:
            return L10n.screenNotificationSettingsModeAll
        case .mentionsAndKeywordsOnly:
            return L10n.screenNotificationSettingsModeMentions
        }
    }
    
    func string(for mode: RoomNotificationModeProxy) -> String {
        switch mode {
        case .allMessages:
            return L10n.screenNotificationSettingsModeAll
        case .mentionsAndKeywordsOnly:
            return L10n.screenNotificationSettingsModeMentions
        case .mute:
            return L10n.commonMute
        }
    }
}

struct NotificationSettingsEditScreenRoom: Identifiable, Equatable {
    static let placeholderLastMessage = AttributedString("Hidden last message")
    
    /// The list item identifier can be a real room identifier, a custom one for invalidated entries
    /// or a completely unique one for empty items and skeletons
    let id: String
    
    /// The real room identifier this item points to
    let roomId: String?
    
    var name = ""
        
    var avatarURL: URL?
    
    var notificationMode: RoomNotificationModeProxy?
    
    var isPlaceholder = false
    
    static func placeholder() -> NotificationSettingsEditScreenRoom {
        NotificationSettingsEditScreenRoom(id: UUID().uuidString,
                                           roomId: nil,
                                           name: "Placeholder room name",
                                           isPlaceholder: true)
    }
}
