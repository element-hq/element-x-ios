//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    var availableDefaultModes: [NotificationSettingsEditScreenDefaultMode] = [.allMessages, .mentionsAndKeywordsOnly]
    var defaultMode: NotificationSettingsEditScreenDefaultMode?
    var pendingMode: NotificationSettingsEditScreenDefaultMode?
    var roomsWithUserDefinedMode: [NotificationSettingsEditScreenRoom] = []
    var canPushEncryptedEvents = false

    func isSelected(mode: NotificationSettingsEditScreenDefaultMode) -> Bool {
        pendingMode == nil && defaultMode == mode
    }
    
    func description(for mode: NotificationSettingsEditScreenDefaultMode) -> String? {
        guard mode == .mentionsAndKeywordsOnly,
              !canPushEncryptedEvents else {
            return nil
        }
        return L10n.screenNotificationSettingsMentionsOnlyDisclaimer
    }
    
    var displayRoomsWithCustomSettings: Bool {
        !roomsWithUserDefinedMode.isEmpty
    }
}

struct NotificationSettingsEditScreenViewStateBindings {
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
    
    init(chatType: NotificationSettingsChatType) {
        switch chatType {
        case .oneToOneChat:
            navigationTitle = L10n.screenNotificationSettingsDirectChats
            modeSectionTitle = L10n.screenNotificationSettingsEditScreenDirectSectionHeader
        case .groupChat:
            navigationTitle = L10n.screenNotificationSettingsGroupChats
            modeSectionTitle = L10n.screenNotificationSettingsEditScreenGroupSectionHeader
        }
    }
    
    func string(for mode: NotificationSettingsEditScreenDefaultMode) -> String {
        switch mode {
        case .allMessages:
            return L10n.screenNotificationSettingsEditModeAllMessages
        case .mentionsAndKeywordsOnly:
            return L10n.screenNotificationSettingsEditModeMentionsAndKeywords
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
    /// The list item identifier can be a real room identifier, a custom one for invalidated entries
    /// or a completely unique one for empty items and skeletons
    let id: String
    
    /// The real room identifier this item points to
    let roomId: String?
    
    var name = ""
        
    var avatar: RoomAvatar
    
    var notificationMode: RoomNotificationModeProxy?
}
