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
    case invited(isDM: Bool)
    case knockable
    case knocked
    case banned(sender: String?, reason: String?)
    case forbidden
}

struct JoinRoomScreenRoomDetails {
    let name: String?
    let topic: String?
    let canonicalAlias: String?
    let avatar: RoomAvatar?
    let memberCount: Int?
    let inviter: RoomInviterDetails?
    let isDirect: Bool?
}

struct JoinRoomScreenViewState: BindableState {
    let roomID: String
    
    var roomDetails: JoinRoomScreenRoomDetails?
    
    var mode: JoinRoomScreenMode = .loading
        
    var bindings = JoinRoomScreenViewStateBindings()
    
    var title: String {
        if isDMInvite, let inviter = roomDetails?.inviter {
            return inviter.displayName ?? inviter.id
        } else {
            return roomDetails?.name ?? L10n.screenJoinRoomTitleNoPreview
        }
    }
    
    var subtitle: String? {
        switch mode {
        case .invited(isDM: true):
            if let inviter = roomDetails?.inviter {
                return inviter.displayName != nil ? inviter.id : nil
            }
            return nil
        case .loading, .unknown, .knocked:
            return nil
        default:
            return roomDetails?.canonicalAlias
        }
    }
    
    var avatar: RoomAvatar? {
        if isDMInvite, let inviter = roomDetails?.inviter {
            return .room(id: roomID, name: inviter.displayName, avatarURL: inviter.avatarURL)
        } else if let avatar = roomDetails?.avatar {
            return avatar
        } else if let name = roomDetails?.name {
            return .room(id: roomID, name: name, avatarURL: nil)
        } else {
            return nil
        }
    }
    
    var isDMInvite: Bool {
        mode == .invited(isDM: true)
    }
}

struct JoinRoomScreenViewStateBindings {
    var alertInfo: AlertInfo<JoinRoomScreenAlertType>?
    var knockMessage = ""
}

enum JoinRoomScreenAlertType {
    case declineInvite
    case declineInviteAndBlock
    case cancelKnock
    case loadingError
}

enum JoinRoomScreenViewAction {
    case cancelKnock
    case knock
    case join
    case acceptInvite
    case declineInvite
    case declineInviteAndBlock(userID: String)
    case forget
    case dismiss
}
