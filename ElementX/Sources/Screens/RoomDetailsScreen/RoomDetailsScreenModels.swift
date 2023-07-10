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
import SwiftUI
import UIKit

// MARK: - Coordinator

// MARK: View model

enum RoomDetailsScreenViewModelAction {
    case requestNotificationSettingsPresentation
    case requestMemberDetailsPresentation
    case requestInvitePeoplePresentation
    case leftRoom
    case requestEditDetailsPresentation(RoomMemberProxyProtocol)
}

// MARK: View

struct RoomDetailsScreenViewState: BindableState {
    let roomId: String
    let canonicalAlias: String?
    let isEncrypted: Bool
    let isDirect: Bool
    let permalink: URL?

    var title = ""
    var topic: String?
    var avatarURL: URL?
    var joinedMembersCount: Int
    var isProcessingIgnoreRequest = false
    var canInviteUsers = false
    var canEditRoomName = false
    var canEditRoomTopic = false
    var canEditRoomAvatar = false
    let showNotificationSettings: Bool
    var notificationSettingsState: RoomDetailsNotificationSettingsState = .loading
    
    var canEdit: Bool {
        !isDirect && (canEditRoomName || canEditRoomTopic || canEditRoomAvatar)
    }
    
    var hasTopicSection: Bool {
        topic != nil || (canEdit && canEditRoomTopic)
    }

    var bindings: RoomDetailsScreenViewStateBindings

    var dmRecipient: RoomMemberDetails?
    
    var shortcuts: [RoomDetailsScreenViewShortcut] {
        var shortcuts: [RoomDetailsScreenViewShortcut] = []
        if showNotificationSettings {
            shortcuts.append(.mute)
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
    
    var notificationShortcutButtonImage: Image {
        areNotificationsMuted ? Image(systemName: "bell.slash.fill") : Image(systemName: "bell")
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

    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<RoomDetailsScreenErrorType>?
    var leaveRoomAlertItem: LeaveRoomAlertItem?
    var ignoreUserRoomAlertItem: IgnoreUserAlertItem?
}

struct LeaveRoomAlertItem: AlertProtocol {
    enum RoomState {
        case empty
        case `public`
        case `private`
    }

    let roomId: String
    let state: RoomState
    let title = L10n.actionLeaveRoom
    let confirmationTitle = L10n.actionLeave
    let cancelTitle = L10n.actionCancel

    var subtitle: String {
        switch state {
        case .empty: return L10n.leaveRoomAlertEmptySubtitle
        case .private: return L10n.leaveRoomAlertPrivateSubtitle
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
    case processToogleMuteNotifications
}

enum RoomDetailsScreenViewShortcut {
    case share(link: URL)
    case mute
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
                return UntranslatedL10n.screenRoomDetailsNotificationModeDefault
            } else {
                return UntranslatedL10n.screenRoomDetailsNotificationModeCustom
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
