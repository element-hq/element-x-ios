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

import SwiftUI

struct RoomMemberDetailsScreen: View {
    @ObservedObject var context: RoomMemberDetailsScreenViewModel.Context
    
    var body: some View {
        Form {
            headerSection

            if !context.viewState.details.isAccountOwner {
                blockUserSection
            }
        }
        .compoundForm()
        .alert(item: $context.ignoreUserAlert, actions: blockUserAlertActions, message: blockUserAlertMessage)
        .alert(item: $context.alertInfo)
        .track(screen: .user)
        .interactiveQuickLook(item: $context.mediaPreviewItem)
    }
    
    // MARK: - Private

    @ViewBuilder
    private var headerSection: some View {
        AvatarHeaderView(avatarUrl: context.viewState.details.avatarURL,
                         name: context.viewState.details.name,
                         id: context.viewState.details.id,
                         avatarSize: .user(on: .memberDetails),
                         imageProvider: context.imageProvider,
                         subtitle: context.viewState.details.id) {
            context.send(viewAction: .displayAvatar)
        } footer: {
            if let permalink = context.viewState.details.permalink {
                HStack(spacing: 32) {
                    ShareLink(item: permalink) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(FormActionButtonStyle(title: L10n.actionShare))
                }
                .padding(.top, 32)
            }
        }
    }

    private var blockUserSection: some View {
        Section {
            Button(role: context.viewState.details.isIgnored ? nil : .destructive) {
                context.send(viewAction: blockUserButtonAction)
            } label: {
                Label(blockUserButtonTitle, systemImage: "slash.circle")
            }
            .accessibilityIdentifier(blockUserButtonAccessibilityIdentifier)
            .buttonStyle(FormButtonStyle(accessory: context.viewState.isProcessingIgnoreRequest ? .progressView : nil))
            .disabled(context.viewState.isProcessingIgnoreRequest)
        }
        .compoundFormSection()
    }

    private var blockUserButtonAction: RoomMemberDetailsScreenViewAction {
        context.viewState.details.isIgnored ? .showUnignoreAlert : .showIgnoreAlert
    }

    private var blockUserButtonTitle: String {
        context.viewState.details.isIgnored ? L10n.screenRoomMemberDetailsUnblockUser : L10n.screenRoomMemberDetailsBlockUser
    }

    private var blockUserButtonAccessibilityIdentifier: String {
        context.viewState.details.isIgnored ? A11yIdentifiers.roomMemberDetailsScreen.unignore : A11yIdentifiers.roomMemberDetailsScreen.ignore
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

struct RoomMemberDetailsScreen_Previews: PreviewProvider {
    static let roomProxyMock = RoomProxyMock(with: .init(displayName: ""))
    static let otherUserViewModel = {
        let member = RoomMemberProxyMock.mockDan
        return RoomMemberDetailsScreenViewModel(roomProxy: roomProxyMock,
                                                roomMemberProxy: member,
                                                mediaProvider: MockMediaProvider(),
                                                userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }()

    static let accountOwnerViewModel = {
        let member = RoomMemberProxyMock.mockMe
        return RoomMemberDetailsScreenViewModel(roomProxy: roomProxyMock,
                                                roomMemberProxy: member,
                                                mediaProvider: MockMediaProvider(),
                                                userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }()

    static let ignoredUserViewModel = {
        let member = RoomMemberProxyMock.mockIgnored
        return RoomMemberDetailsScreenViewModel(roomProxy: roomProxyMock,
                                                roomMemberProxy: member,
                                                mediaProvider: MockMediaProvider(),
                                                userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }()
    
    static var previews: some View {
        RoomMemberDetailsScreen(context: otherUserViewModel.context)
            .previewDisplayName("Other User")
        RoomMemberDetailsScreen(context: accountOwnerViewModel.context)
            .previewDisplayName("Account Owner")
        RoomMemberDetailsScreen(context: ignoredUserViewModel.context)
            .previewDisplayName("Ignored User")
    }
}
