//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct InviteUsersScreenSelectedItem: View {
    let user: UserProfileProxy
    let mediaProvider: MediaProviderProtocol?
    var isLocked = false
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 10) {
            avatar
                .accessibilityHidden(true)
            
            Text(user.displayName ?? user.userID)
                .font(.compound.bodySM)
                .foregroundColor(.compound.textSecondary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityActions {
            if !isLocked {
                Button(L10n.actionRemove, action: dismissAction)
            }
        }
    }
    
    // MARK: - Private
    
    @ViewBuilder
    var avatar: some View {
        let avatarImage = LoadableAvatarImage(url: user.avatarURL,
                                              name: user.displayName,
                                              contentID: user.userID,
                                              avatarSize: .user(on: .inviteUsers),
                                              mediaProvider: mediaProvider)
        if isLocked {
            avatarImage
        } else {
            avatarImage.overlayRemoveItemButton(action: dismissAction)
        }
    }
    
    var closeButtonLabel: some View {
        CompoundIcon(\.close, size: .custom(12), relativeTo: .compound.bodySM)
            .foregroundStyle(.compound.iconOnSolidPrimary)
            .padding(2)
            .background(.compound.iconPrimary, in: Circle())
    }
}

struct InviteUsersScreenSelectedItem_Previews: PreviewProvider, TestablePreview {
    static let people: [UserProfileProxy] = [.mockAlice, .mockVerbose]
    
    static var previews: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 8) {
                ForEach(people, id: \.userID) { user in
                    InviteUsersScreenSelectedItem(user: user, mediaProvider: MediaProviderMock(configuration: .init())) { }
                        .frame(width: 80)
                }
            }
        }
    }
}
