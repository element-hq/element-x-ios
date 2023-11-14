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

enum RoomNotificationSettingsScreenViewModelAction {
    case openGlobalSettings
    case dismiss
}

enum RoomNotificationSettingsState {
    case loading
    case loaded(settings: RoomNotificationSettingsProxyProtocol)
    case error
}

extension RoomNotificationSettingsState {
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

struct RoomNotificationSettingsScreenViewState: BindableState {
    var bindings: RoomNotificationSettingsScreenViewStateBindings
    let strings = RoomNotificationSettingsScreenStrings()
    var notificationSettingsState: RoomNotificationSettingsState = .loading
    var availableCustomRoomNotificationModes: [RoomNotificationModeProxy] = [.allMessages, .mentionsAndKeywordsOnly, .mute]
    var isRestoringDefaultSetting = false
    var pendingCustomMode: RoomNotificationModeProxy?
    var displayAsUserDefinedRoomSettings = false
    var navigationTitle: String
    var customSettingsSectionHeader: String
    var deletingCustomSetting = false
    var shouldDisplayMentionsOnlyDisclaimer = true
    
    func description(mode: RoomNotificationModeProxy) -> String? {
        guard mode == .mentionsAndKeywordsOnly,
              shouldDisplayMentionsOnlyDisclaimer else {
            return nil
        }
        return L10n.screenRoomNotificationSettingsMentionsOnlyDisclaimer
    }
    
    func isSelected(mode: RoomNotificationModeProxy) -> Bool {
        if case .loaded(let settings) = notificationSettingsState, settings.mode == mode, pendingCustomMode == nil {
            return true
        }
        return false
    }
}

struct RoomNotificationSettingsScreenViewStateBindings {
    var allowCustomSetting = false
    var customMode: RoomNotificationModeProxy = .allMessages
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomNotificationSettingsScreenErrorType>?
}

enum RoomNotificationSettingsScreenViewAction {
    case changedAllowCustomSettings
    case setCustomMode(RoomNotificationModeProxy)
    case customSettingFootnoteLinkTapped
    case deleteCustomSettingTapped
}

struct RoomNotificationSettingsScreenStrings {
    let customSettingFootnote: AttributedString
    let customSettingFootnoteLink: URL?
    
    init() {
        customSettingFootnoteLink = URL(string: "element://openGlobalSettings")
        
        let linkPlaceholder = "{link}"
        var customSettingFootnote = AttributedString(L10n.screenRoomNotificationSettingsDefaultSettingFootnote(linkPlaceholder))
        var linkString = AttributedString(L10n.screenRoomNotificationSettingsDefaultSettingFootnoteContentLink)
        linkString.link = customSettingFootnoteLink
        linkString.bold()
        customSettingFootnote.replace(linkPlaceholder, with: linkString)
        
        self.customSettingFootnote = customSettingFootnote
    }
        
    func string(for mode: RoomNotificationModeProxy) -> String {
        switch mode {
        case .allMessages:
            return L10n.screenRoomNotificationSettingsModeAllMessages
        case .mentionsAndKeywordsOnly:
            return L10n.screenRoomNotificationSettingsModeMentionsAndKeywords
        case .mute:
            return L10n.commonMute
        }
    }
    
    func string(for state: RoomNotificationSettingsState) -> String {
        switch state {
        case .loading:
            return L10n.commonLoading
        case .loaded(let settings):
            return string(for: settings.mode)
        case .error:
            return L10n.commonError
        }
    }
}

enum RoomNotificationSettingsScreenErrorType: Hashable {
    case loadingSettingsFailed
    case setModeFailed
    case restoreDefaultFailed
}
