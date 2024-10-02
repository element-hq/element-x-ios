//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum RoomMemberDetailsScreenViewModelAction {
    case openUserProfile
    case openDirectChat(roomID: String)
    case startCall(roomID: String)
}

struct RoomMemberDetailsScreenViewState: BindableState {
    let userID: String
    var memberDetails: RoomMemberDetails?
    var isOwnMemberDetails = false
    var isProcessingIgnoreRequest = false
    var dmRoomID: String?

    var bindings: RoomMemberDetailsScreenViewStateBindings
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
    var alertInfo: AlertInfo<RoomMemberDetailsScreenError>?
    
    /// A media item that will be previewed with QuickLook.
    var mediaPreviewItem: MediaPreviewItem?
}

enum RoomMemberDetailsScreenViewAction {
    case showUnignoreAlert
    case showIgnoreAlert
    case ignoreConfirmed
    case unignoreConfirmed
    case displayAvatar
    case openDirectChat
    case startCall(roomID: String)
}

enum RoomMemberDetailsScreenError: Hashable {
    case failedOpeningDirectChat
    case unknown
}
