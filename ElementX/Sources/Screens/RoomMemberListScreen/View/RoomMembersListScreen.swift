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
                membersSection(data: context.viewState.visibleInvitedMembers, sectionTitle: L10n.screenRoomMemberListPendingHeaderTitle)
                membersSection(data: context.viewState.visibleJoinedMembers, sectionTitle: L10n.screenRoomMemberListHeaderTitle(Int(context.viewState.joinedMembersCount)))
            }
        }
        .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always))
        .compoundSearchField()
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .navigationTitle(L10n.commonPeople)
        .alert(item: $context.alertInfo)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                inviteButton
            }
        }
    }
    
    // MARK: - Private
    
    private func membersSection(data: [RoomMemberDetails], sectionTitle: String) -> some View {
        Section {
            ForEach(data, id: \.id) { member in
                RoomMembersListScreenMemberCell(member: member, context: context)
            }
        } header: {
            if !data.isEmpty {
                Text(sectionTitle)
                    .foregroundColor(.compound.textSecondary)
                    .font(.compound.bodyLG)
                    .padding(.vertical, 12)
            }
        }
        .padding(.horizontal)
    }
    
    @ViewBuilder
    private var inviteButton: some View {
        if context.viewState.canInviteUsers {
            Button {
                context.send(viewAction: .invite)
            } label: {
                Text(L10n.actionInvite)
            }
        }
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
        return RoomMembersListScreenViewModel(roomProxy: RoomProxyMock(with: .init(displayName: "Some room", members: members)),
                                              mediaProvider: MockMediaProvider())
    }()
    
    static var previews: some View {
        NavigationStack {
            RoomMembersListScreen(context: viewModel.context)
        }
    }
}
