//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

// MARK: - Coordinator

// MARK: View model

enum RoomDetailsScreenViewModelAction: Equatable {
    case requestNotificationSettingsPresentation
    case requestMemberDetailsPresentation
    case requestRecipientDetailsPresentation(userID: String)
    case requestInvitePeoplePresentation
    case leftRoom
    case requestEditDetailsPresentation
    case requestPollsHistoryPresentation
    case requestRolesAndPermissionsPresentation
    case startCall
    case displayPinnedEventsTimeline
    case displayMediaEventsTimeline
    case displayKnockingRequests
    case displaySecurityAndPrivacy
    case displayReportRoom
    case transferOwnership
}

// MARK: View

struct DMRecipientInfo {
    var member: RoomMemberDetails
    var verificationState: UserIdentityVerificationState?
}

struct RoomDetailsScreenViewState: BindableState {
    var details: RoomDetails
    
    var isEncrypted: Bool
    var isDirect: Bool
    var permalink: URL?

    var topic: AttributedString?
    var topicSummary: AttributedString?
    
    var joinedMembersCount: Int
    var hasMemberIdentityVerificationStateViolations = false
    
    var isProcessingIgnoreRequest = false
    var canInviteUsers = false
    var canEditRoomName = false
    var canEditRoomTopic = false
    var canEditRoomAvatar = false
    var canEditRolesOrPermissions = false
    var canEditSecurityAndPrivacy = false
    var canKickUsers = false
    var canBanUsers = false
    var notificationSettingsState: RoomDetailsNotificationSettingsState = .loading
    var canJoinCall = false
    var pinnedEventsActionState = RoomDetailsScreenPinnedEventsActionState.loading
    
    var knockingEnabled = false
    var isKnockableRoom = false
    var knockRequestsCount = 0
    
    var reportRoomEnabled = false
    
    var canSeeKnockingRequests: Bool {
        knockingEnabled && dmRecipientInfo == nil && isKnockableRoom && (canInviteUsers || canKickUsers || canBanUsers)
    }
    
    var canSeeSecurityAndPrivacy: Bool {
        dmRecipientInfo == nil && canEditSecurityAndPrivacy
    }
    
    var canEditBaseInfo: Bool {
        !isDirect && (canEditRoomName || canEditRoomTopic || canEditRoomAvatar)
    }
    
    var hasTopicSection: Bool {
        topic != nil || canEditRoomTopic
    }

    var bindings: RoomDetailsScreenViewStateBindings

    var dmRecipientInfo: DMRecipientInfo?
    var accountOwner: RoomMemberDetails?
    
    var shortcuts: [RoomDetailsScreenViewShortcut] {
        var shortcuts: [RoomDetailsScreenViewShortcut] = [.mute]
        if !ProcessInfo.processInfo.isiOSAppOnMac, canJoinCall {
            shortcuts.append(.call)
        }
        if dmRecipientInfo == nil, canInviteUsers {
            shortcuts.append(.invite)
        }
        if let permalink = dmRecipientInfo?.member.permalink {
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
    
    /// The view model used to display the leave space sheet, will only be used if the room is a space.
    var leaveSpaceViewModel: LeaveSpaceViewModel?
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
    case processTapRecipientProfile
    case processToggleMuteNotifications
    case displayAvatar(URL)
    case processTapPolls
    case toggleFavourite(isFavourite: Bool)
    case processTapRolesAndPermissions
    case processTapSecurityAndPrivacy
    case processTapCall
    case processTapPinnedEvents
    case processTapMediaEvents
    case processTapRequestsToJoin
    case processTapReport
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
    /// Last owner
    case lastOwner
}

enum RoomDetailsScreenPinnedEventsActionState {
    case loading
    case loaded(numberOfItems: Int)
    
    var count: String {
        switch self {
        case .loading:
            return ""
        case .loaded(let numberOfItems):
            return "\(numberOfItems)"
        }
    }
    
    var isLoading: Bool {
        switch self {
        case .loading:
            return true
        default:
            return false
        }
    }
}
