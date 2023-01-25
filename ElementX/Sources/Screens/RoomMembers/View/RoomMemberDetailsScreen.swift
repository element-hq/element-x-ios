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
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var context: RoomMemberDetailsViewModel.Context
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                Section {
                    ForEach(context.viewState.visibleMembers) { member in
                        RoomMemberDetailsMemberCell(member: member, context: context)
                            .id(member.id)
                    }
                } header: {
                    Text(ElementL10n.roomTitleMembers(context.viewState.members.count))
                        .foregroundColor(.element.secondaryContent)
                        .font(.element.body)
                        .padding(.vertical, 12)
                }
                .padding(.horizontal)
            }
        }
        .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always))
        .alert(item: $context.alertInfo) { $0.alert }
        .navigationTitle(ElementL10n.bottomActionPeople)
    }
}

// MARK: - Previews

struct RoomMemberDetails_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let members: [RoomMemberProxy] = [
                .mockAlice,
                .mockBob,
                .mockCharlie
            ]
            let viewModel = RoomMemberDetailsViewModel(mediaProvider: MockMediaProvider(),
                                                       members: members)
            RoomMemberDetailsScreen(context: viewModel.context)
        }
        .tint(.element.accent)
    }
}
