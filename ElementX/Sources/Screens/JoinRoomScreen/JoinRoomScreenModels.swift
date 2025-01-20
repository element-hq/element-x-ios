//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum JoinRoomScreenViewModelAction {
    case joined
    case dismiss
}

enum JoinRoomScreenMode: Equatable {
    case loading
    case unknown
    case joinable
    case restricted
    case inviteRequired
    case invited
    case knockable
    case knocked
    case banned(sender: String?, reason: String?)
}

struct JoinRoomScreenRoomDetails {
    let name: String?
    let topic: String?
    let canonicalAlias: String?
    let avatar: RoomAvatar
    let memberCount: UInt
    let inviter: RoomInviterDetails?
}

struct JoinRoomScreenViewState: BindableState {
    let roomID: String
    
    var roomDetails: JoinRoomScreenRoomDetails?
    
    var mode: JoinRoomScreenMode = .loading
    
    var bindings = JoinRoomScreenViewStateBindings()
    
    var title: String {
        roomDetails?.name ?? L10n.screenJoinRoomTitleNoPreview
    }
    
    var subtitle: String? {
        switch mode {
        case .loading:
            nil
        case .unknown:
            L10n.screenJoinRoomSubtitleNoPreview
        case .knocked:
            nil
        default:
            roomDetails?.canonicalAlias
        }
    }
    
    var avatar: RoomAvatar {
        roomDetails?.avatar ?? .room(id: roomID, name: title, avatarURL: nil)
    }
}

struct JoinRoomScreenViewStateBindings {
    var alertInfo: AlertInfo<JoinRoomScreenAlertType>?
    var knockMessage = ""
}

enum JoinRoomScreenAlertType {
    case declineInvite
    case cancelKnock
}

enum JoinRoomScreenViewAction {
    case cancelKnock
    case knock
    case join
    case acceptInvite
    case declineInvite
}
