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
                ForEach(context.viewState.blockedUsers, id: \.self) { userID in
                    ListRow(label: .avatar(title: userID, icon: avatar(for: userID)),
                            details: .isWaiting(context.viewState.processingUserID == userID),
                            kind: .button(action: { context.send(viewAction: .unblockUser(userID: userID)) }))
                }
            }
        }
    }
    
    private func avatar(for userID: String) -> some View {
        LoadableAvatarImage(url: nil,
                            name: String(userID.dropFirst()),
                            contentID: userID,
                            avatarSize: .user(on: .blockedUsers),
                            imageProvider: nil)
            .accessibilityHidden(true)
    }
}

// MARK: - Previews

struct BlockedUsersScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = BlockedUsersScreenViewModel(clientProxy: ClientProxyMock(.init(userID: RoomMemberProxyMock.mockMe.userID)),
                                                       userIndicatorController: UserIndicatorControllerMock())
    
    static var previews: some View {
        NavigationStack {
            BlockedUsersScreen(context: viewModel.context)
        }
    }
}
