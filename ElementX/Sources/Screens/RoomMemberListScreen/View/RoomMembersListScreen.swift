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
            if context.viewState.canBanUsers {
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
        .overlay {
            if context.mode == .banned, context.viewState.bannedMembersCount == 0 {
                Text(L10n.screenRoomMemberListBannedEmpty)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .frame(maxWidth: .infinity)
                    .background(.compound.bgCanvasDefault)
            }
        }
        .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always))
        .compoundSearchField()
        .autocorrectionDisabled()
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .navigationTitle(L10n.commonPeople)
        .sheet(item: $context.memberToManage) {
            RoomMembersListManageMemberSheet(member: $0, context: context)
        }
        .alert(item: $context.alertInfo)
        .toolbar { toolbar }
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
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if context.viewState.canInviteUsers {
                Button(L10n.actionInvite) {
                    context.send(viewAction: .invite)
                }
            }
        }
    }
}

// MARK: - Previews

struct RoomMembersListScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let invitesViewModel = makeViewModel(withInvites: true)
    static let adminViewModel = makeViewModel(isAdmin: true, initialMode: .members)
    static let bannedViewModel = makeViewModel(isAdmin: true, initialMode: .banned)
    static let emptyBannedViewModel = makeViewModel(withBanned: false, isAdmin: true, initialMode: .banned)
    
    static var previews: some View {
        NavigationStack {
            RoomMembersListScreen(context: viewModel.context)
        }
        .snapshot(delay: 1.0)
        .previewDisplayName("Member")
        
        NavigationStack {
            RoomMembersListScreen(context: invitesViewModel.context)
        }
        .snapshot(delay: 1.0)
        .previewDisplayName("Invites")
        
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
        
        NavigationStack {
            RoomMembersListScreen(context: emptyBannedViewModel.context)
        }
        .snapshot(delay: 1.0)
        .previewDisplayName("Admin: Empty Banned")
    }
    
    static func makeViewModel(withInvites: Bool = false,
                              withBanned: Bool = true,
                              isAdmin: Bool = false,
                              initialMode: RoomMembersListScreenMode = .members) -> RoomMembersListScreenViewModel {
        let mockAdmin = RoomMemberProxyMock.mockAdmin
        
        let ownUserID = isAdmin ? mockAdmin.userID : RoomMemberProxyMock.mockMe.userID
        
        var members: [RoomMemberProxyMock] = [
            .mockAlice,
            .mockBob,
            .mockCharlie,
            mockAdmin,
            .mockModerator
        ]
        
        if withBanned {
            members.append(contentsOf: RoomMemberProxyMock.mockBanned)
        }
        
        if withInvites {
            members.append(.mockInvited)
        }
        
        return RoomMembersListScreenViewModel(initialMode: initialMode,
                                              roomProxy: RoomProxyMock(with: .init(name: "Some room",
                                                                                   members: members,
                                                                                   ownUserID: ownUserID,
                                                                                   canUserInvite: false)),
                                              mediaProvider: MockMediaProvider(),
                                              userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                              appSettings: ServiceLocator.shared.settings)
    }
}
