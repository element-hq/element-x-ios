//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import MatrixRustSDK
import SwiftUI

struct UserProfileListRow: View {
    let user: UserProfileProxy
    let membership: MembershipState?
    let mediaProvider: MediaProviderProtocol?
    
    let kind: ListRow<LoadableAvatarImage, EmptyView, EmptyView, Bool>.Kind<EmptyView, Bool>
    
    private var subtitle: String? {
        // GUA FORK: never surface Matrix protocol details ("This Matrix ID can't be
        // found…") to end users. Show the membership state when known, otherwise the
        // abstracted handle (homeserver hidden) as the secondary line.
        if let membershipText = membership?.localizedDescription {
            return membershipText
        } else if user.displayName != nil {
            return user.userID.guaDisplayHandle
        } else {
            return nil
        }
    }

    var body: some View {
        ListRow(label: .avatar(title: user.displayName ?? user.userID.guaDisplayHandle,
                               description: subtitle,
                               icon: avatar,
                               role: nil),
                kind: kind)
    }
    
    var avatar: LoadableAvatarImage {
        LoadableAvatarImage(url: user.avatarURL,
                            name: user.displayName,
                            contentID: user.userID,
                            avatarSize: .user(on: .startChat),
                            mediaProvider: mediaProvider)
    }
}

private extension MembershipState {
    var localizedDescription: String? {
        switch self {
        case .join:
            return L10n.screenInviteUsersAlreadyAMember
        case .invite:
            return L10n.screenInviteUsersAlreadyInvited
        default:
            return nil
        }
    }
}

struct UserProfileCell_Previews: PreviewProvider, TestablePreview {
    static let action: () -> Void = { }
    
    static var previews: some View {
        Form {
            UserProfileListRow(user: .mockAlice, membership: nil, mediaProvider: MediaProviderMock(configuration: .init()),
                               kind: .multiSelection(isSelected: true, action: action))
            
            UserProfileListRow(user: .mockBob, membership: nil, mediaProvider: MediaProviderMock(configuration: .init()),
                               kind: .multiSelection(isSelected: false, action: action))
            
            UserProfileListRow(user: .mockCharlie, membership: .join, mediaProvider: MediaProviderMock(configuration: .init()),
                               kind: .multiSelection(isSelected: true, action: action))
                .disabled(true)
            
            UserProfileListRow(user: .init(userID: "@someone:matrix.org"), membership: .join, mediaProvider: MediaProviderMock(configuration: .init()),
                               kind: .multiSelection(isSelected: false, action: action))
                .disabled(true)
            
            UserProfileListRow(user: .init(userID: "@someone:matrix.org"), membership: nil, mediaProvider: MediaProviderMock(configuration: .init()),
                               kind: .multiSelection(isSelected: false, action: action))
        }
        .compoundList()
    }
}
