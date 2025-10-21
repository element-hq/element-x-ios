//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum RoomMemberDetailsScreenViewModelAction {
    case openUserProfile
    case openDirectChat(roomID: String)
    case startCall(roomProxy: JoinedRoomProxyProtocol)
    case verifyUser(userID: String)
}

struct RoomMemberDetailsScreenViewState: BindableState {
    let userID: String
    var memberDetails: RoomMemberDetails?
    var verificationState: UserIdentityVerificationState?
    var isOwnMemberDetails = false
    var isProcessingIgnoreRequest = false
    var dmRoomID: String?

    var bindings: RoomMemberDetailsScreenViewStateBindings
    
    var showVerifiedBadge: Bool {
        verificationState == .verified // We purposely show the badge on your own account for consistency with Web.
    }
    
    var showVerifyIdentitySection: Bool {
        verificationState == .notVerified && !isOwnMemberDetails
    }
    
    var showWithdrawVerificationSection: Bool {
        verificationState == .verificationViolation && !isOwnMemberDetails
    }
}

struct RoomMemberDetailsScreenViewStateBindings {
    struct IgnoreUserAlertItem: AlertProtocol, Equatable {
        enum Action {
            case ignore
            case unignore
        }

        let action: Action
        let cancelTitle = L10n.actionCancel

        var title: String {
            switch action {
            case .ignore: return L10n.screenRoomMemberDetailsBlockUser
            case .unignore: return L10n.screenRoomMemberDetailsUnblockUser
            }
        }

        var confirmationTitle: String {
            switch action {
            case .ignore: return L10n.screenRoomMemberDetailsBlockAlertAction
            case .unignore: return L10n.screenRoomMemberDetailsUnblockAlertAction
            }
        }

        var description: String {
            switch action {
            case .ignore: return L10n.screenRoomMemberDetailsBlockAlertDescription
            case .unignore: return L10n.screenRoomMemberDetailsUnblockAlertDescription
            }
        }

        var viewAction: RoomMemberDetailsScreenViewAction {
            switch action {
            case .ignore: return .ignoreConfirmed
            case .unignore: return .unignoreConfirmed
            }
        }
    }
    
    var ignoreUserAlert: IgnoreUserAlertItem?
    var alertInfo: AlertInfo<RoomMemberDetailsScreenAlertType>?
    var inviteConfirmationUser: UserProfileProxy?
    
    /// A media item that will be previewed with QuickLook.
    var mediaPreviewItem: MediaPreviewItem?
}

enum RoomMemberDetailsScreenViewAction {
    case showUnignoreAlert
    case showIgnoreAlert
    case ignoreConfirmed
    case unignoreConfirmed
    case displayAvatar(URL)
    case openDirectChat
    case createDirectChat
    case startCall(roomID: String)
    case verifyUser
    case withdrawVerification
}

enum RoomMemberDetailsScreenAlertType: Hashable {
    case failedOpeningDirectChat
    case unknown
}
