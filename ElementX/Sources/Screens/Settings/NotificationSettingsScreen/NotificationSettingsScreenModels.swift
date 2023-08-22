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
import UIKit

enum NotificationSettingsScreenViewModelAction {
    case close
    case editDefaultMode(chatType: NotificationSettingsChatType)
}

struct NotificationSettingsScreenViewState: BindableState {
    var bindings: NotificationSettingsScreenViewStateBindings
    var strings = NotificationSettingsScreenStrings()
    let isModallyPresented: Bool
    var isUserPermissionGranted: Bool?
    var allowedNotificationModes: [RoomNotificationModeProxy] = [.allMessages, .mentionsAndKeywordsOnly]
    var fixingConfigurationMismatch = false
    
    var showSystemNotificationsAlert: Bool {
        bindings.enableNotifications && isUserPermissionGranted == false
    }

    var settings: NotificationSettingsScreenSettings?
    var applyingChange = false
}

struct NotificationSettingsScreenViewStateBindings {
    var enableNotifications = false
    var roomMentionsEnabled = false
    var callsEnabled = false
    var alertInfo: AlertInfo<NotificationSettingsScreenErrorType>?
}

struct NotificationSettingsScreenSettings {
    let groupChatsMode: RoomNotificationModeProxy
    let directChatsMode: RoomNotificationModeProxy
    let roomMentionsEnabled: Bool?
    let callsEnabled: Bool?
    // Old clients were having specific settings for encrypted and unencrypted rooms,
    // so it's possible for `group chats` and `direct chats` settings to be inconsistent (e.g. encrypted `direct chats` can have a different mode that unencrypted `direct chats`)
    let inconsistentSettings: [NotificationSettingsScreenSettingsChatMismatchConfiguration]
}

struct NotificationSettingsScreenSettingsChatMismatchConfiguration: Equatable {
    let type: NotificationSettingsChatType
    let isEncrypted: Bool
}

struct NotificationSettingsScreenStrings {
    let changeYourSystemSettings: AttributedString = {
        let linkPlaceholder = "{link}"
        var text = AttributedString(L10n.screenNotificationSettingsSystemNotificationsActionRequired(linkPlaceholder))
        var linkString = AttributedString(L10n.screenNotificationSettingsSystemNotificationsActionRequiredContentLink)
        // Note: On the simulator, `UIApplication.openNotificationSettingsURLString` opens the `Settings` application instead of the application's notification settings screen.
        linkString.link = URL(string: UIApplication.openNotificationSettingsURLString)
        linkString.bold()
        text.replace(linkPlaceholder, with: linkString)
        
        return text
    }()
    
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

enum NotificationSettingsScreenViewAction {
    case linkClicked(url: URL)
    case changedEnableNotifications
    case groupChatsTapped
    case directChatsTapped
    case roomMentionChanged
    case callsChanged
    case close
    case fixConfigurationMismatchTapped
}

enum NotificationSettingsScreenErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert
    case fixMismatchConfigurationFailed
}
