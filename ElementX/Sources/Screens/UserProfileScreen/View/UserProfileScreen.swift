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

struct UserProfileScreen: View {
    @ObservedObject var context: UserProfileScreenViewModel.Context
    
    var body: some View {
        Form {
            headerSection
            
            if context.viewState.userProfile != nil, !context.viewState.isOwnUser {
                directChatSection
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenRoomMemberDetailsTitle)
        .alert(item: $context.alertInfo)
        .track(screen: .User)
        .interactiveQuickLook(item: $context.mediaPreviewItem, shouldHideControls: true)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var headerSection: some View {
        if let userProfile = context.viewState.userProfile {
            AvatarHeaderView(user: userProfile,
                             avatarSize: .user(on: .memberDetails),
                             imageProvider: context.imageProvider) {
                context.send(viewAction: .displayAvatar)
            } footer: {
                if let permalink = context.viewState.permalink {
                    HStack(spacing: 32) {
                        ShareLink(item: permalink) {
                            CompoundIcon(\.shareIos)
                        }
                        .buttonStyle(FormActionButtonStyle(title: L10n.actionShare))
                    }
                    .padding(.top, 32)
                }
            }
        } else {
            AvatarHeaderView(user: UserProfileProxy(userID: context.viewState.userID),
                             avatarSize: .user(on: .memberDetails),
                             imageProvider: context.imageProvider,
                             footer: { })
        }
    }
    
    private var directChatSection: some View {
        Section {
            ListRow(label: .default(title: L10n.commonDirectChat,
                                    icon: \.chat),
                    kind: .button {
                        context.send(viewAction: .openDirectChat)
                    })
                    .accessibilityIdentifier(A11yIdentifiers.roomMemberDetailsScreen.directChat)
        }
    }
}

// MARK: - Previews

struct UserProfileScreen_Previews: PreviewProvider, TestablePreview {
    static let otherUserViewModel = makeViewModel(userID: RoomMemberProxyMock.mockDan.userID)
    static let accountOwnerViewModel = makeViewModel(userID: RoomMemberProxyMock.mockMe.userID)
    
    static var previews: some View {
        UserProfileScreen(context: otherUserViewModel.context)
            .previewDisplayName("Other User")
            .snapshot(delay: 0.25)
        UserProfileScreen(context: accountOwnerViewModel.context)
            .previewDisplayName("Account Owner")
            .snapshot(delay: 0.25)
    }
    
    static func makeViewModel(userID: String) -> UserProfileScreenViewModel {
        UserProfileScreenViewModel(userID: userID,
                                   clientProxy: ClientProxyMock(.init()),
                                   mediaProvider: MockMediaProvider(),
                                   userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
