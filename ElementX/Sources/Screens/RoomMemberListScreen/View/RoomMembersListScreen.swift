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
    @ObservedObject var context: RoomMembersListScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            if context.viewState.canBanUsers,
               context.viewState.bannedMembersCount > 0 {
                // Maybe this should go into the search bar if it can be pinned when not focussed?
                Picker("", selection: $context.mode) {
                    Text(L10n.screenRoomMemberListModeMembers)
                        .tag(RoomMembersListScreenMode.members)
                    Text(L10n.screenRoomMemberListModeBanned)
                        .tag(RoomMembersListScreenMode.banned)
                }
                .pickerStyle(.segmented)
                .padding(.horizontal, 16)
            }
            
            if context.mode == .members {
                roomMembers
            } else {
                bannedUsers
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
        .track(screen: .RoomMembers)
    }
    
    // MARK: - Private
    
    var roomMembers: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            membersSection(data: context.viewState.visibleInvitedMembers, sectionTitle: L10n.screenRoomMemberListPendingHeaderTitle)
            membersSection(data: context.viewState.visibleJoinedMembers, sectionTitle: L10n.screenRoomMemberListHeaderTitle(Int(context.viewState.joinedMembersCount)))
        }
    }
    
    var bannedUsers: some View {
        LazyVStack(alignment: .leading, spacing: 12) {
            membersSection(data: context.viewState.visibleBannedMembers)
        }
    }
    
    @ViewBuilder
    private func membersSection(data: [RoomMemberDetails], sectionTitle: String? = nil) -> some View {
        if !data.isEmpty {
            Section {
                ForEach(data, id: \.id) { member in
                    RoomMembersListScreenMemberCell(member: member, context: context)
                }
            } header: {
                if let sectionTitle {
                    Text(sectionTitle)
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodyLG)
                        .padding(.top, 12)
                } else {
                    // Put something in here to maintain constant top padding.
                    Spacer().frame(height: 0)
                }
            }
            .padding(.horizontal, 16)
        }
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

struct RoomMembersListScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let adminViewModel = makeViewModel(isAdmin: true, initialMode: .members)
    static let bannedViewModel = makeViewModel(isAdmin: true, initialMode: .banned)
    
    static var previews: some View {
        NavigationStack {
            RoomMembersListScreen(context: viewModel.context)
        }
        .snapshot(delay: 1.0)
        .previewDisplayName("Member")
        
        NavigationStack {
            RoomMembersListScreen(context: adminViewModel.context)
        }
        .snapshot(delay: 1.0)
        .previewDisplayName("Admin: Members")
        
        NavigationStack {
            RoomMembersListScreen(context: bannedViewModel.context)
        }
        .snapshot(delay: 1.0)
        .previewDisplayName("Admin: Banned")
    }
    
    static func makeViewModel(isAdmin: Bool = false, initialMode: RoomMembersListScreenMode = .members) -> RoomMembersListScreenViewModel {
        let mockAdmin = RoomMemberProxyMock.mockAdmin
        
        if isAdmin {
            mockAdmin.underlyingCanBanUsers = true
            mockAdmin.underlyingIsAccountOwner = true
        }
        
        let members: [RoomMemberProxyMock] = [
            .mockAlice,
            .mockBob,
            .mockCharlie,
            mockAdmin,
            .mockModerator
        ] + RoomMemberProxyMock.mockBanned
        
        return RoomMembersListScreenViewModel(initialMode: initialMode,
                                              roomProxy: RoomProxyMock(with: .init(displayName: "Some room", members: members)),
                                              mediaProvider: MockMediaProvider(),
                                              userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}
