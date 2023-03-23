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
        let member = RoomMemberProxyMock.mockDan
        return RoomMemberDetailsViewModel(roomMemberProxy: member, mediaProvider: MockMediaProvider())
    }()
    
    static var previews: some View {
        RoomMemberDetailsScreen(context: viewModel.context)
    }
}
