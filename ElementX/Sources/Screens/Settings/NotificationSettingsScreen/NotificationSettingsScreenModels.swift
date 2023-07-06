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

enum NotificationSettingsScreenViewModelAction { }

struct NotificationSettingsScreenViewState: BindableState {
    var bindings: NotificationSettingsScreenViewStateBindings
    var strings = NotificationSettingsScreenStrings()
    var isUserPermissionGranted: Bool?
    
    var showSystemNotificationsAlert: Bool {
        bindings.enableNotifications && isUserPermissionGranted == false
    }
}

struct NotificationSettingsScreenViewStateBindings {
    var enableNotifications = false
}

struct NotificationSettingsScreenStrings {
    let changeYourSystemSettings: AttributedString = {
        let linkPlaceholder = "{link}"
        var text = AttributedString(L10n.screenNotificationSettingsSystemNotificationsActionRequired(linkPlaceholder))
        text.font = .compound.bodySM
        text.foregroundColor = .compound.textSecondary
        var linkString = AttributedString(L10n.screenNotificationSettingsSystemNotificationsActionRequiredContentLink)
        linkString.font = .compound.bodySM
        linkString.bold()
        linkString.foregroundColor = .compound.textPrimary
        text.replace(linkPlaceholder, with: linkString)
        
        return text
    }()
}

enum NotificationSettingsScreenViewAction {
    case openSystemSettings
    case changedEnableNotifications
}
