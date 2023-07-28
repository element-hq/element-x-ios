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

enum NotificationSettingsEditScreenViewModelAction { }

enum NotificationSettingsEditScreenDefaultMode {
    case allMessages
    case mentionsAndKeywordsOnly
}

struct NotificationSettingsEditScreenViewState: BindableState {
    var bindings: NotificationSettingsEditScreenViewStateBindings
    var strings: NotificationSettingsEditScreenStrings
    var isDirect: Bool
    var availableDefaultModes: [NotificationSettingsEditScreenDefaultMode] = [.allMessages, .mentionsAndKeywordsOnly]
    var pendingMode: NotificationSettingsEditScreenDefaultMode?
    var defaultMode: NotificationSettingsEditScreenDefaultMode?
    
    func isSelected(mode: NotificationSettingsEditScreenDefaultMode) -> Bool {
        pendingMode == nil && defaultMode == mode
    }
}

struct NotificationSettingsEditScreenViewStateBindings {
    var alertInfo: AlertInfo<NotificationSettingsEditScreenErrorType>?
}

enum NotificationSettingsEditScreenViewAction {
    case setMode(NotificationSettingsEditScreenDefaultMode)
}

enum NotificationSettingsEditScreenErrorType: Hashable {
    case loadingModeFailed
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
}
