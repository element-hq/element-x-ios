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
    @ObservedObject var context: RoomMemberDetailsViewModel.Context
    
    var body: some View {
        Form {
            headerSection

//            if !context.viewState.isAccountOwner {
//                blockUserSection
//            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.element.formBackground.ignoresSafeArea())
        .alert(item: $context.blockUserAlertItem, actions: blockUserAlertActions(_:), message: blockUserAlertMessage(_:))
        .errorAlert(item: $context.errorAlert)
    }
    
    // MARK: - Private

    private var headerSection: some View {
        VStack(spacing: 8.0) {
            LoadableAvatarImage(url: context.viewState.avatarURL,
                                name: context.viewState.name,
                                contentID: context.viewState.userID,
                                avatarSize: .user(on: .memberDetails),
                                imageProvider: context.imageProvider)

            Text(context.viewState.name)
                .foregroundColor(.element.primaryContent)
                .font(.element.title1Bold)
                .multilineTextAlignment(.center)
            Text(context.viewState.userID)
                .foregroundColor(.element.secondaryContent)
                .font(.element.body)
                .multilineTextAlignment(.center)

            if let permalink = context.viewState.permalink {
                HStack(spacing: 32) {
                    Button { context.send(viewAction: .copyUserLink) } label: {
                        Image(systemName: "link")
                    }
                    .buttonStyle(FormActionButtonStyle(title: ElementL10n.actionCopyLink))

                    ShareLink(item: permalink) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .buttonStyle(FormActionButtonStyle(title: ElementL10n.actionShareLink))
                }
                .padding(.top, 32)
            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
    }

    private var blockUserSection: some View {
        Section {
            if context.viewState.isIgnored {
                Button {
                    context.send(viewAction: .unblockTapped)
                } label: {
                    Label(ElementL10n.roomMemberDetailsUnblockUser, systemImage: "slash.circle")
                }
                .buttonStyle(FormButtonStyle(accessory: nil))
            } else {
                Button(role: .destructive) {
                    context.send(viewAction: .blockTapped)
                } label: {
                    Label(ElementL10n.roomMemberDetailsBlockUser, systemImage: "slash.circle")
                }
                .buttonStyle(FormButtonStyle(accessory: nil))
            }
        }
        .formSectionStyle()
    }

    @ViewBuilder
    private func blockUserAlertActions(_ item: BlockUserAlertItem) -> some View {
        Button(item.cancelTitle, role: .cancel) { }
        Button(item.confirmationTitle,
               role: item.action == .block ? .destructive : nil) {
            context.send(viewAction: item.viewAction)
        }
    }

    private func blockUserAlertMessage(_ item: BlockUserAlertItem) -> some View {
        Text(item.description)
    }
}

// MARK: - Previews

struct RoomMemberDetails_Previews: PreviewProvider {
    static let otherUserViewModel = {
        let member = RoomMemberProxyMock.mockDan
        return RoomMemberDetailsViewModel(roomMemberProxy: member, mediaProvider: MockMediaProvider())
    }()

    static let accountOwnerViewModel = {
        let member = RoomMemberProxyMock.mockMe
        return RoomMemberDetailsViewModel(roomMemberProxy: member, mediaProvider: MockMediaProvider())
    }()

    static let ignoredUserViewModel = {
        let member = RoomMemberProxyMock.mockIgnored
        return RoomMemberDetailsViewModel(roomMemberProxy: member, mediaProvider: MockMediaProvider())
    }()
    
    static var previews: some View {
        Group {
            RoomMemberDetailsScreen(context: otherUserViewModel.context)
                .previewDisplayName("Other User")
            RoomMemberDetailsScreen(context: accountOwnerViewModel.context)
                .previewDisplayName("Account Owner")
            RoomMemberDetailsScreen(context: ignoredUserViewModel.context)
                .previewDisplayName("Ignored User")
        }
    }
}
