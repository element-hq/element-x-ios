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

struct RoomMembersScreen: View {
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var context: RoomMembersViewModel.Context
    
    var body: some View {
        Form {
            Section {
                ForEach(context.viewState.visibleMembers, id: \.id) { member in
                    RoomMembersMemberCell(member: member, context: context)
                        .id(member.id)
                }
            } footer: {
                Text(ElementL10n.roomTitleMembers(context.viewState.members.count))
                    .foregroundColor(.element.secondaryContent)
                    .font(.element.footnote)
            }
        }
        .searchable(text: $context.searchQuery)
        .ignoresSafeArea(.all, edges: .bottom)
        .alert(item: $context.alertInfo) { $0.alert }
        .navigationTitle(ElementL10n.listMembers)
    }
}

// MARK: - Previews

struct RoomMembers_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let viewModel = RoomMembersViewModel(roomProxy: MockRoomProxy(displayName: "Room A"),
                                                 mediaProvider: MockMediaProvider())
            RoomMembersScreen(context: viewModel.context)
        }
        .tint(.element.accent)
    }
}
