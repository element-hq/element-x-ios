//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    var fixingConfigurationMismatch = false
    // Hide calls settings until calls are available in El-X
    let showCallsSettings = false
    
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
    var invitationsEnabled = false
    var alertInfo: AlertInfo<NotificationSettingsScreenErrorType>?
}

struct NotificationSettingsScreenSettings {
    let groupChatsMode: RoomNotificationModeProxy
    let directChatsMode: RoomNotificationModeProxy
    let roomMentionsEnabled: Bool?
    let callsEnabled: Bool?
    let invitationsEnabled: Bool?
    // Old clients were having specific settings for encrypted and unencrypted rooms,
    // so it's possible for `group chats` and `direct chats` settings to be inconsistent (e.g. encrypted `direct chats` can have a different mode that unencrypted `direct chats`)
    let inconsistentSettings: [NotificationSettingsScreenInvalidSetting]
}

struct NotificationSettingsScreenInvalidSetting: Equatable {
    let chatType: NotificationSettingsChatType
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
    case changedEnableNotifications
    case groupChatsTapped
    case directChatsTapped
    case roomMentionChanged
    case callsChanged
    case invitationsChanged
    case close
    case fixConfigurationMismatchTapped
}

enum NotificationSettingsScreenErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert
    case fixMismatchConfigurationFailed
}
