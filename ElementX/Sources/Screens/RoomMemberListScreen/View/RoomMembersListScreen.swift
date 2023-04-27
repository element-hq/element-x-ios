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

struct RoomMembersListScreen: View {
    @Environment(\.colorScheme) private var colorScheme

    @ObservedObject var context: RoomMembersListScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading) {
                Section {
                    ForEach(context.viewState.visibleMembers) { member in
                        RoomMembersListScreenMemberCell(member: member, context: context)
                            .id(member.id)
                    }
                } header: {
                    Text(L10n.commonMemberCount(context.viewState.members.count))
                        .foregroundColor(.element.secondaryContent)
                        .font(.compound.bodyLG)
                        .padding(.vertical, 12)
                }
                .padding(.horizontal)
            }
        }
        .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always))
        .compoundSearchField()
        .background(Color.element.background.ignoresSafeArea())
        .navigationTitle(L10n.commonPeople)
        .alert(item: $context.alertInfo) { $0.alert }
    }
}

// MARK: - Previews

struct RoomMembersListScreen_Previews: PreviewProvider {
    static let viewModel = {
        let members: [RoomMemberProxyMock] = [
            .mockAlice,
            .mockBob,
            .mockCharlie
        ]
        return RoomMembersListScreenViewModel(mediaProvider: MockMediaProvider(),
                                              members: members)
    }()
    
    static var previews: some View {
        NavigationStack {
            RoomMembersListScreen(context: viewModel.context)
        }
    }
}
