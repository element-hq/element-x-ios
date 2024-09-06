//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct BlockedUsersScreen: View {
    @ObservedObject var context: BlockedUsersScreenViewModel.Context
    
    var body: some View {
        content
            .compoundList()
            .navigationBarTitleDisplayMode(.inline)
            .navigationTitle(L10n.commonBlockedUsers)
            .alert(item: $context.alertInfo)
            .disabled(context.viewState.processingUserID != nil)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var content: some View {
        if context.viewState.blockedUsers.isEmpty {
            Text(L10n.screenBlockedUsersEmpty)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textSecondary)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
        } else {
            Form {
                ForEach(context.viewState.blockedUsers, id: \.self) { user in
                    ListRow(label: .avatar(title: user.displayName ?? user.userID, icon: avatar(for: user)),
                            details: .isWaiting(context.viewState.processingUserID == user.userID),
                            kind: .button(action: { context.send(viewAction: .unblockUser(user)) }))
                }
            }
        }
    }
    
    private func avatar(for user: UserProfileProxy) -> some View {
        LoadableAvatarImage(url: user.avatarURL,
                            name: user.displayName,
                            contentID: user.userID,
                            avatarSize: .user(on: .blockedUsers),
                            mediaProvider: context.mediaProvider)
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

struct BlockedUsersScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = BlockedUsersScreenViewModel(hideProfiles: true,
                                                       clientProxy: ClientProxyMock(.init(userID: RoomMemberProxyMock.mockMe.userID)),
                                                       mediaProvider: MockMediaProvider(),
                                                       userIndicatorController: UserIndicatorControllerMock())
    
    static var previews: some View {
        NavigationStack {
            BlockedUsersScreen(context: viewModel.context)
        }
    }
}
