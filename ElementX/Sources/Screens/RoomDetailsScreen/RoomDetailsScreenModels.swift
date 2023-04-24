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
import UIKit

// MARK: - Coordinator

// MARK: View model

enum RoomDetailsScreenViewModelAction {
    case requestMemberDetailsPresentation([RoomMemberProxyProtocol])
    case leftRoom
    case cancel
}

// MARK: View

struct RoomDetailsScreenViewState: BindableState {
    let roomId: String
    let canonicalAlias: String?
    let isEncrypted: Bool
    let isDirect: Bool
    var title = ""
    var topic: String?
    var avatarURL: URL?
    let permalink: URL?
    var members: [RoomMemberDetails] = []
    var isProcessingIgnoreRequest = false
    
    var isLoadingMembers: Bool {
        members.isEmpty
    }

    var bindings: RoomDetailsScreenViewStateBindings

    var dmRecipient: RoomMemberDetails?

    private var isDMRoom: Bool {
        isEncrypted && isDirect && members.count == 2
    }
}

struct RoomDetailsScreenViewStateBindings {
    struct IgnoreUserAlertItem: AlertItem, Equatable {
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

struct LeaveRoomAlertItem: AlertItem {
    enum RoomState {
        case empty
        case `public`
        case `private`
    }

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
    case processTapLeave
    case processTapIgnore
    case processTapUnignore
    case confirmLeave
    case ignoreConfirmed
    case unignoreConfirmed
}

enum RoomDetailsScreenErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert(String)
    /// Leaving room has failed..
    case unknown
}
