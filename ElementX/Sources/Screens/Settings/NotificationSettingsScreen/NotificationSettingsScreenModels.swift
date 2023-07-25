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

enum NotificationSettingsScreenViewModelAction { }

struct NotificationSettingsScreenViewState: BindableState {
    var bindings: NotificationSettingsScreenViewStateBindings
    var strings = NotificationSettingsScreenStrings()
    var isUserPermissionGranted: Bool?
    var allowedNotificationModes: [RoomNotificationModeProxy] = [.allMessages, .mentionsAndKeywordsOnly]
    
    var showSystemNotificationsAlert: Bool {
        bindings.enableNotifications && isUserPermissionGranted == false
    }
    
    var groupChatNotificationSettingsState: NotificationSettingsScreenModeState = .loading
    var directChatNotificationSettingsState: NotificationSettingsScreenModeState = .loading
    var applyingChange = false
    var inconsistentGroupChatsSettings = false
    var inconsistentDirectChatsSettings = false
}

struct NotificationSettingsScreenViewStateBindings {
    var enableNotifications = false
    var enableRoomMention = false
    var enableCalls = false
    var alertInfo: AlertInfo<NotificationSettingsScreenErrorType>?
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
    case processTapGroupChats
    case processTapDirectChats
    case processToggleRoomMention
    case processToggleCalls
}

enum NotificationSettingsScreenModeState {
    case loading
    case loaded(mode: RoomNotificationModeProxy)
    case error
}

extension NotificationSettingsScreenModeState {
    var isLoading: Bool {
        if case .loading = self {
            return true
        }
        return false
    }
    
    var isLoaded: Bool {
        if case .loaded = self {
            return true
        }
        return false
    }
    
    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}

enum NotificationSettingsScreenErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert
}
