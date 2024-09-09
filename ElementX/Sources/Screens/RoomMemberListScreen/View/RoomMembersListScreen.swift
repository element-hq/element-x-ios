//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        .searchable(text: $context.searchQuery,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: L10n.commonSearchForSomeone)
        .compoundSearchField()
        .autocorrectionDisabled()
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .navigationTitle(L10n.commonPeople)
        .sheet(item: $context.memberToManage) {
            RoomMembersListManageMemberSheet(member: $0.member, actions: $0.actions, context: context)
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
        .snapshotPreferences(delay: 1.0)
        .previewDisplayName("Member")
        
        NavigationStack {
            RoomMembersListScreen(context: invitesViewModel.context)
        }
        .snapshotPreferences(delay: 1.0)
        .previewDisplayName("Invites")
        
        NavigationStack {
            RoomMembersListScreen(context: adminViewModel.context)
        }
        .snapshotPreferences(delay: 1.0)
        .previewDisplayName("Admin: Members")
        
        NavigationStack {
            RoomMembersListScreen(context: bannedViewModel.context)
        }
        .snapshotPreferences(delay: 1.0)
        .previewDisplayName("Admin: Banned")
        
        NavigationStack {
            RoomMembersListScreen(context: emptyBannedViewModel.context)
        }
        .snapshotPreferences(delay: 1.0)
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
                                              roomProxy: JoinedRoomProxyMock(.init(name: "Some room",
                                                                                   members: members,
                                                                                   ownUserID: ownUserID,
                                                                                   canUserInvite: false)),
                                              mediaProvider: MockMediaProvider(),
                                              userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                              analytics: ServiceLocator.shared.analytics)
    }
}
