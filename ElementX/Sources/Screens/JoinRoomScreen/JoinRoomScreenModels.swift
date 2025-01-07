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

enum JoinRoomScreenInteractionMode {
    case loading
    case unknown
    case invited
    case join
    case knock
    case knocked
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
    // Maybe use room summary details or similar here??
    let roomID: String
    
    var roomDetails: JoinRoomScreenRoomDetails?
    
    var mode: JoinRoomScreenInteractionMode = .loading
    
    var bindings = JoinRoomScreenViewStateBindings()
    
    var title: String {
        roomDetails?.name ?? L10n.screenJoinRoomTitleNoPreview
    }
    
    var subtitle: String? {
        switch mode {
        case .loading: nil
        case .unknown: L10n.screenJoinRoomSubtitleNoPreview
        case .invited, .join, .knock: roomDetails?.canonicalAlias
        case .knocked: nil
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
