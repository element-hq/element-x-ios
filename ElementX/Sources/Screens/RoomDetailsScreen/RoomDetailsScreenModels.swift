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

import Compound
import SwiftUI

// MARK: - Coordinator

// MARK: View model

enum RoomDetailsScreenViewModelAction {
    case requestNotificationSettingsPresentation
    case requestMemberDetailsPresentation
    case requestInvitePeoplePresentation
    case leftRoom
    case requestEditDetailsPresentation
    case requestPollsHistoryPresentation
    case requestRolesAndPermissionsPresentation
    case startCall
}

// MARK: View

struct RoomDetailsScreenViewState: BindableState {
    var details: RoomDetails
    
    let isEncrypted: Bool
    let isDirect: Bool
    var permalink: URL?

    var topic: AttributedString?
    var topicSummary: AttributedString?
    var joinedMembersCount: Int
    var isProcessingIgnoreRequest = false
    var canInviteUsers = false
    var canEditRoomName = false
    var canEditRoomTopic = false
    var canEditRoomAvatar = false
    var canEditRolesOrPermissions = false
    var notificationSettingsState: RoomDetailsNotificationSettingsState = .loading
    var canJoinCall = false
    
    var canEdit: Bool {
        !isDirect && (canEditRoomName || canEditRoomTopic || canEditRoomAvatar)
    }
    
    var hasTopicSection: Bool {
        topic != nil || (canEdit && canEditRoomTopic)
    }

    var bindings: RoomDetailsScreenViewStateBindings

    var dmRecipient: RoomMemberDetails?
    
    var shortcuts: [RoomDetailsScreenViewShortcut] {
        var shortcuts: [RoomDetailsScreenViewShortcut] = [.mute]
        if !ProcessInfo.processInfo.isiOSAppOnMac, canJoinCall {
            shortcuts.append(.call)
        }
        if dmRecipient == nil, canInviteUsers {
            shortcuts.append(.invite)
        }
        if let permalink = dmRecipient?.permalink {
            shortcuts.append(.share(link: permalink))
        } else if let permalink {
            shortcuts.append(.share(link: permalink))
        }
        return shortcuts
    }
    
    var isProcessingMuteToggleAction = false
    
    var areNotificationsMuted: Bool {
        if case .loaded(let settings) = notificationSettingsState {
            return settings.mode == .mute
        }
        return false
    }
    
    var notificationShortcutButtonTitle: String {
        areNotificationsMuted ? L10n.commonUnmute : L10n.commonMute
    }
    
    var notificationShortcutButtonIcon: KeyPath<CompoundIcons, Image> {
        areNotificationsMuted ? \.notificationsOff : \.notifications
    }
}

struct RoomDetailsScreenViewStateBindings {
    struct IgnoreUserAlertItem: AlertProtocol, Equatable {
        enum Action {
            case ignore
            case unignore
        }

        let action: Action
        let cancelTitle = L10n.actionCancel

        var title: String {
            switch action {
            case .ignore: return L10n.screenDmDetailsBlockUser
            case .unignore: return L10n.screenDmDetailsUnblockUser
            }
        }

        var confirmationTitle: String {
            switch action {
            case .ignore: return L10n.screenDmDetailsBlockAlertAction
            case .unignore: return L10n.screenDmDetailsUnblockAlertAction
            }
        }

        var description: String {
            switch action {
            case .ignore: return L10n.screenDmDetailsBlockAlertDescription
            case .unignore: return L10n.screenDmDetailsUnblockAlertDescription
            }
        }

        var viewAction: RoomDetailsScreenViewAction {
            switch action {
            case .ignore: return .ignoreConfirmed
            case .unignore: return .unignoreConfirmed
            }
        }
    }
    
    var isFavourite = false

    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomDetailsScreenErrorType>?
    var leaveRoomAlertItem: LeaveRoomAlertItem?
    var ignoreUserRoomAlertItem: IgnoreUserAlertItem?
    
    /// A media item that will be previewed with QuickLook.
    var mediaPreviewItem: MediaPreviewItem?
}

struct LeaveRoomAlertItem: AlertProtocol {
    enum RoomState {
        case empty
        case `public`
        case `private`
    }

    let roomID: String
    let isDM: Bool
    let state: RoomState
    let confirmationTitle = L10n.actionLeave
    let cancelTitle = L10n.actionCancel
    
    var title: String {
        isDM ? L10n.actionLeaveConversation : L10n.actionLeaveRoom
    }

    var subtitle: String {
        switch state {
        case .empty: return L10n.leaveRoomAlertEmptySubtitle
        case .private: return isDM ? L10n.leaveConversationAlertSubtitle : L10n.leaveRoomAlertPrivateSubtitle
        case .public: return L10n.leaveRoomAlertSubtitle
        }
    }
}

enum RoomDetailsScreenViewAction {
    case processTapPeople
    case processTapInvite
    case processTapLeave
    case processTapIgnore
    case processTapUnignore
    case processTapEdit
    case processTapAddTopic
    case confirmLeave
    case ignoreConfirmed
    case unignoreConfirmed
    case processTapNotifications
    case processToggleMuteNotifications
    case displayAvatar
    case processTapPolls
    case toggleFavourite(isFavourite: Bool)
    case processTapRolesAndPermissions
    case processTapCall
}

enum RoomDetailsScreenViewShortcut {
    case share(link: URL)
    case mute
    case call
    case invite
}

extension RoomDetailsScreenViewShortcut: Hashable { }

enum RoomDetailsNotificationSettingsState {
    case loading
    case loaded(settings: RoomNotificationSettingsProxyProtocol)
    case error
}

extension RoomDetailsNotificationSettingsState {
    var label: String {
        switch self {
        case .loading:
            return L10n.commonLoading
        case .loaded(let settings):
            if settings.isDefault {
                return L10n.screenRoomDetailsNotificationModeDefault
            } else {
                return L10n.screenRoomDetailsNotificationModeCustom
            }
        case .error:
            return L10n.commonError
        }
    }
    
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
    
    /// Returns `true` when the settings are loaded and `isDefault` is false.
    var isCustom: Bool {
        guard case let .loaded(settings) = self else { return false }
        return !settings.isDefault
    }
    
    var isError: Bool {
        if case .error = self {
            return true
        }
        return false
    }
}

enum RoomDetailsScreenErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert
    /// Leaving room has failed..
    case unknown
}
