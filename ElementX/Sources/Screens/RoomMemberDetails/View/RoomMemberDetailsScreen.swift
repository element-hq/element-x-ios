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

            blockUserSection
        }
        .scrollContentBackground(.hidden)
        .background(Color.element.formBackground.ignoresSafeArea())
//        .alert(item: $context.alertInfo) { $0.alert }
    }
    
    // MARK: - Private

    private var headerSection: some View {
        VStack(spacing: 8.0) {
            LoadableAvatarImage(url: context.viewState.avatarURL,
                                name: context.viewState.name,
                                contentID: context.viewState.userID,
                                avatarSize: .user(on: .memberDetails),
                                imageProvider: context.imageProvider)
                .accessibilityIdentifier(A11yIdentifiers.roomDetailsScreen.avatar)

            Text(context.viewState.name)
                .foregroundColor(.element.primaryContent)
                .font(.element.title1Bold)
                .multilineTextAlignment(.center)

//            if let canonicalAlias = context.viewState.canonicalAlias {
//                Text(canonicalAlias)
//                    .foregroundColor(.element.secondaryContent)
//                    .font(.element.body)
//                    .multilineTextAlignment(.center)
//            }
//
//            if let permalink = context.viewState.permalink {
//                HStack(spacing: 32) {
//                    Button { context.send(viewAction: .copyRoomLink) } label: {
//                        Image(systemName: "link")
//                    }
//                    .buttonStyle(FormActionButtonStyle(title: ElementL10n.roomDetailsCopyLink))
//
//                    ShareLink(item: permalink) {
//                        Image(systemName: "square.and.arrow.up")
//                    }
//                    .buttonStyle(FormActionButtonStyle(title: ElementL10n.inviteUsersToRoomActionInvite.capitalized))
//                }
//                .padding(.top, 32)
//            }
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .listRowBackground(Color.clear)
    }

    private var blockUserSection: some View {
        EmptyView()
    }
}

// MARK: - Previews

struct RoomMemberDetails_Previews: PreviewProvider {
    static let viewModel = {
        let member = RoomMemberProxyMock.mockAlice
        return RoomMemberDetailsViewModel(roomMemberProxy: member, mediaProvider: MockMediaProvider())
    }()
    
    static var previews: some View {
        RoomMemberDetailsScreen(context: viewModel.context)
    }
}
