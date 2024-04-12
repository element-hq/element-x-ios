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

struct RoomMemberDetailsScreen: View {
    @ObservedObject var context: RoomMemberDetailsScreenViewModel.Context
    
    var body: some View {
        Form {
            headerSection
            
            if context.viewState.memberDetails != nil, !context.viewState.isOwnMemberDetails {
                directChatSection
                blockUserSection
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenRoomMemberDetailsTitle)
        .alert(item: $context.ignoreUserAlert, actions: blockUserAlertActions, message: blockUserAlertMessage)
        .alert(item: $context.alertInfo)
        .track(screen: .User)
        .interactiveQuickLook(item: $context.mediaPreviewItem, shouldHideControls: true)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var headerSection: some View {
        if let memberDetails = context.viewState.memberDetails {
            AvatarHeaderView(member: memberDetails,
                             avatarSize: .user(on: .memberDetails),
                             imageProvider: context.imageProvider) {
                context.send(viewAction: .displayAvatar)
            } footer: {
                if let permalink = memberDetails.permalink {
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

    @ViewBuilder
    private var blockUserSection: some View {
        if let memberDetails = context.viewState.memberDetails {
            let title = memberDetails.isIgnored ? L10n.screenRoomMemberDetailsUnblockUser : L10n.screenRoomMemberDetailsBlockUser
            let action: RoomMemberDetailsScreenViewAction = memberDetails.isIgnored ? .showUnignoreAlert : .showIgnoreAlert
            let accessibilityIdentifier = memberDetails.isIgnored ? A11yIdentifiers.roomMemberDetailsScreen.unignore : A11yIdentifiers.roomMemberDetailsScreen.ignore
            
            Section {
                ListRow(label: .default(title: title,
                                        icon: \.block,
                                        role: memberDetails.isIgnored ? nil : .destructive),
                        details: .isWaiting(context.viewState.isProcessingIgnoreRequest),
                        kind: .button {
                            context.send(viewAction: action)
                        })
                        .accessibilityIdentifier(accessibilityIdentifier)
                        .disabled(context.viewState.isProcessingIgnoreRequest)
            }
        }
    }

    @ViewBuilder
    private func blockUserAlertActions(_ item: RoomMemberDetailsScreenViewStateBindings.IgnoreUserAlertItem) -> some View {
        Button(item.cancelTitle, role: .cancel) { }
        Button(item.confirmationTitle,
               role: item.action == .ignore ? .destructive : nil) {
            context.send(viewAction: item.viewAction)
        }
    }

    private func blockUserAlertMessage(_ item: RoomMemberDetailsScreenViewStateBindings.IgnoreUserAlertItem) -> some View {
        Text(item.description)
    }
}

// MARK: - Previews

struct RoomMemberDetailsScreen_Previews: PreviewProvider, TestablePreview {
    static let otherUserViewModel = {
        let member = RoomMemberProxyMock.mockDan
        let roomProxyMock = RoomProxyMock(with: .init(name: ""))
        roomProxyMock.getMemberUserIDReturnValue = .success(member)
        
        return RoomMemberDetailsScreenViewModel(userID: member.userID,
                                                roomProxy: roomProxyMock,
                                                clientProxy: ClientProxyMock(.init()),
                                                mediaProvider: MockMediaProvider(),
                                                userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }()

    static let accountOwnerViewModel = {
        let member = RoomMemberProxyMock.mockMe
        let roomProxyMock = RoomProxyMock(with: .init(name: ""))
        roomProxyMock.getMemberUserIDReturnValue = .success(member)
        
        return RoomMemberDetailsScreenViewModel(userID: member.userID,
                                                roomProxy: roomProxyMock,
                                                clientProxy: ClientProxyMock(.init()),
                                                mediaProvider: MockMediaProvider(),
                                                userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }()

    static let ignoredUserViewModel = {
        let member = RoomMemberProxyMock.mockIgnored
        let roomProxyMock = RoomProxyMock(with: .init(name: ""))
        roomProxyMock.getMemberUserIDReturnValue = .success(member)
        
        return RoomMemberDetailsScreenViewModel(userID: member.userID,
                                                roomProxy: roomProxyMock,
                                                clientProxy: ClientProxyMock(.init()),
                                                mediaProvider: MockMediaProvider(),
                                                userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }()
    
    static var previews: some View {
        RoomMemberDetailsScreen(context: otherUserViewModel.context)
            .previewDisplayName("Other User")
            .snapshot(delay: 0.25)
        RoomMemberDetailsScreen(context: accountOwnerViewModel.context)
            .previewDisplayName("Account Owner")
            .snapshot(delay: 0.25)
        RoomMemberDetailsScreen(context: ignoredUserViewModel.context)
            .previewDisplayName("Ignored User")
            .snapshot(delay: 0.25)
    }
}
