//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct InviteUsersScreenSelectedItem: View {
    let user: UserProfileProxy
    let mediaProvider: MediaProviderProtocol?
    let dismissAction: () -> Void
    
    var body: some View {
        VStack(spacing: 0) {
            avatar
                .accessibilityHidden(true)
            
            Text(user.displayName ?? user.userID)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textPrimary)
                .lineLimit(1)
        }
        .accessibilityElement(children: .combine)
        .accessibilityAction(named: L10n.actionRemove, dismissAction)
    }
    
    // MARK: - Private
    
    var avatar: some View {
        LoadableAvatarImage(url: user.avatarURL,
                            name: user.displayName,
                            contentID: user.userID,
                            avatarSize: .user(on: .inviteUsers),
                            mediaProvider: mediaProvider)
            .overlay(alignment: .topTrailing) {
                Button(action: dismissAction) {
                    Image(systemName: "xmark.circle.fill")
                        .resizable()
                        .scaledFrame(size: 20)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.compound.iconOnSolidPrimary, Color.compound.iconPrimary)
                }
            }
    }
}

struct InviteUsersScreenSelectedItem_Previews: PreviewProvider, TestablePreview {
    static let people: [UserProfileProxy] = [.mockAlice, .mockVerbose]
    
    static var previews: some View {
        ScrollView(.horizontal) {
            HStack(spacing: 28) {
                ForEach(people, id: \.userID) { user in
                    InviteUsersScreenSelectedItem(user: user, mediaProvider: MediaProviderMock(configuration: .init())) { }
                        .frame(width: 72)
                }
            }
        }
    }
}
