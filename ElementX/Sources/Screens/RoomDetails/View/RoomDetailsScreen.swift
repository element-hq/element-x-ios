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

struct RoomDetailsScreen: View {
    // MARK: Private
    
    @Environment(\.colorScheme) private var colorScheme

    // MARK: Public
    
    @ObservedObject var context: RoomDetailsViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        ScrollView {
            LazyVStack {
                roomAvatarImage

                ForEach(context.viewState.members) { member in
                    RoomDetailsMemberCell(member: member, context: context)
                }
            }
            .padding(.horizontal)
//            .searchable(text: $context.searchQuery)
        }
        .ignoresSafeArea(.all, edges: .bottom)
        .alert(item: $context.alertInfo) { $0.alert }
        .navigationTitle(ElementL10n.allChats)
    }

    @ViewBuilder private var roomAvatarImage: some View {
        if let avatar = context.viewState.roomAvatar {
            Image(uiImage: avatar)
                .resizable()
                .aspectRatio(1, contentMode: .fill)
                .accessibilityIdentifier("roomAvatarImage")
        } else {
            PlaceholderAvatarImage(text: context.viewState.roomTitle,
                                   contentId: context.viewState.roomId)
                .accessibilityIdentifier("roomAvatarPlaceholderImage")
        }
    }
}

// MARK: - Previews

struct RoomDetails_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let viewModel = RoomDetailsViewModel(roomProxy: MockRoomProxy(displayName: "Room A"),
                                                 mediaProvider: MockMediaProvider())
            RoomDetailsScreen(context: viewModel.context)
        }
        .tint(.element.accent)
    }
}
