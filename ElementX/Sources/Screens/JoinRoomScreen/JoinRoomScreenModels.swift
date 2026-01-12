//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

enum JoinRoomScreenViewModelAction {
    case joined(JoinRoomScreenJoinDetails)
    case dismiss
    case presentDeclineAndBlock(userID: String)
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
    
    var isInvite: Bool {
        switch self {
        case .invited:
            true
        default:
            false
        }
    }
}

struct JoinRoomScreenRoomDetails {
    let name: String?
    let topic: String?
    let canonicalAlias: String?
    let avatar: RoomAvatar?
    let memberCount: Int?
    let heroes: [UserProfileProxy]
    let inviter: RoomInviterDetails?
    let isDirect: Bool?
    
    let isSpace: Bool?
    let childrenCount: Int?
    let spaceVisibility: SpaceServiceRoomVisibility?
}

struct JoinRoomScreenViewState: BindableState {
    let roomID: String
    
    var roomDetails: JoinRoomScreenRoomDetails?
    
    var mode: JoinRoomScreenMode = .loading
    
    var hideInviteAvatars = false
        
    var bindings = JoinRoomScreenViewStateBindings()
    
    var shouldHideAvatars: Bool {
        hideInviteAvatars && mode.isInvite
    }
    
    var title: String {
        if isDMInvite, let inviter = roomDetails?.inviter {
            return inviter.displayName ?? inviter.id
        } else {
            return roomDetails?.name ?? L10n.screenJoinRoomTitleNoPreview
        }
    }
    
    var subtitle: String? {
        if roomDetails?.isSpace == true, let spaceVisibilityTitle {
            return spaceVisibilityTitle
        } else {
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
    }
    
    var subtitleIcon: KeyPath<CompoundIcons, Image>? {
        guard roomDetails?.isSpace == true else { return nil }
        
        return switch roomDetails?.spaceVisibility {
        case .public: \.public
        case .private: \.lock
        case .restricted: \.space
        case .none: \.lock
        }
    }
    
    var spaceVisibilityTitle: String? {
        switch roomDetails?.spaceVisibility {
        case .public: L10n.commonPublicSpace
        case .private: L10n.commonPrivateSpace
        case .restricted: L10n.commonSharedSpace
        case .none: L10n.commonPrivateSpace
        }
    }
    
    var avatar: RoomAvatar? {
        // DM invites avatars are broken, this is a workaround
        // https://github.com/matrix-org/matrix-rust-sdk/issues/4825
        if isDMInvite, let inviter = roomDetails?.inviter {
            .heroes([.init(userID: inviter.id, displayName: inviter.displayName, avatarURL: hideInviteAvatars ? nil : inviter.avatarURL)])
        } else if let avatar = roomDetails?.avatar {
            shouldHideAvatars ? avatar.removingAvatar : avatar
        } else if let name = roomDetails?.name {
            .room(id: roomID, name: name, avatarURL: nil)
        } else {
            nil
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
    case invalidInvite
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
