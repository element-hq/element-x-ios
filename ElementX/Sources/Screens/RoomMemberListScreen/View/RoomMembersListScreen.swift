//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct RoomMembersListScreen: View {
    @ObservedObject var context: RoomMembersListScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            if context.viewState.canBanUsers, context.viewState.bannedMembersCount > 0 {
                Picker("", selection: $context.mode) {
                    Text(L10n.screenRoomMemberListModeMembers)
                        .tag(RoomMembersListScreenMode.members)
                    Text(L10n.screenRoomMemberListModeBanned)
                        .tag(RoomMembersListScreenMode.banned)
                }
                .pickerStyle(.segmented)
                .padding(ListRowPadding.insets)
            }
            
            if context.viewState.shouldShowEmptyState {
                emptySearchView
            } else {
                Spacer()
                    .frame(height: 18)
                switch context.mode {
                case .members:
                    roomMembers
                case .banned:
                    bannedUsers
                }
            }
        }
        .compoundList()
        .searchable(text: $context.searchQuery,
                    placement: .navigationBarDrawer(displayMode: .always),
                    prompt: L10n.commonSearchForSomeone)
        .compoundSearchField()
        .autocorrectionDisabled()
        .navigationTitle(L10n.commonPeople)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $context.manageMemeberViewModel) {
            ManageRoomMemberSheetView(context: $0.context)
        }
        .alert(item: $context.alertInfo)
        .toolbar { toolbar }
        .track(screen: .RoomMembers)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    var roomMembers: some View {
        membersSection(entries: context.viewState.visibleInvitedMembers, section: .invited)
        membersSection(entries: context.viewState.visibleJoinedMembers, section: .joined)
    }
    
    var bannedUsers: some View {
        membersSection(entries: context.viewState.visibleBannedMembers, section: .banned)
    }
    
    @ViewBuilder
    private func membersSection(entries: [RoomMemberListScreenEntry], section: MembersSection) -> some View {
        if !entries.isEmpty {
            Section {
                LazyVStack(alignment: .leading, spacing: 0) {
                    ForEach(entries, id: \.member.id) { entry in
                        ListRow(kind: .custom {
                            RoomMembersListScreenMemberCell(listEntry: entry, isLast: entries.last == entry, context: context)
                        })
                    }
                }
                .background(.compound.bgCanvasDefaultLevel1)
                .clipShape(sectionShape)
                .padding(.bottom, 32)
            } header: {
                section.header(count: entries.count)
            }
            .padding(.horizontal, 16)
        }
    }
    
    private var sectionShape: AnyShape {
        if #available(iOS 26, *) {
            AnyShape(ConcentricRectangle(corners: .concentric(minimum: 26)))
        } else {
            AnyShape(RoundedRectangle(cornerRadius: 8))
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            if context.viewState.canInviteUsers {
                Button(L10n.actionInvite) {
                    context.send(viewAction: .invite)
                }
                .accessibilityIdentifier(A11yIdentifiers.roomMembersListScreen.invite)
            }
        }
    }
    
    private var emptySearchView: some View {
        VStack(spacing: 16) {
            BigIcon(icon: \.search, style: .default)
                .accessibilityHidden(true)
            VStack(spacing: 8) {
                Text(L10n.screenRoomMemberListEmptySearchTitle(context.searchQuery))
                    .font(.compound.headingMDBold)
                    .foregroundStyle(.compound.textPrimary)
                    .frame(maxWidth: .infinity)
                Text(L10n.screenRoomMemberListEmptySearchSubtitle)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .frame(maxWidth: .infinity)
            }
        }
        .accessibilityElement(children: .combine)
        .padding(.horizontal, 24)
        .padding(.top, 40)
    }
}

private enum MembersSection {
    case joined
    case invited
    case banned
    
    private func sectionTitle(count: Int) -> String {
        switch self {
        case .banned:
            L10n.screenRoomMemberListBannedHeaderTitle(count)
        case .invited:
            L10n.screenRoomMemberListPendingHeaderTitle(count)
        case .joined:
            L10n.screenRoomMemberListHeaderTitle(count)
        }
    }
    
    @ViewBuilder
    private func text(count: Int) -> some View {
        switch self {
        case .invited, .joined:
            Text(sectionTitle(count: count))
        case .banned:
            Text(sectionTitle(count: count))
                .foregroundStyle(.compound.bgCriticalPrimary)
        }
    }
    
    func header(count: Int) -> some View {
        text(count: count)
            .compoundListSectionHeader()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.leading, 16)
    }
}

// MARK: - Previews

struct RoomMembersListScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let invitesViewModel = makeViewModel(withInvites: true)
    static let adminViewModel = makeViewModel(isAdmin: true, initialMode: .members)
    static let bannedViewModel = makeViewModel(isAdmin: true, initialMode: .banned)
    static let emptyBannedViewModel = makeViewModel(withBanned: false, isAdmin: false, initialMode: .members)
    
    static var previews: some View {
        NavigationStack {
            RoomMembersListScreen(context: viewModel.context)
        }
        .snapshotPreferences(expect: viewModel.context.$viewState.map { state in
            !state.visibleJoinedMembers.isEmpty
        })
        .previewDisplayName("Member")
        
        NavigationStack {
            RoomMembersListScreen(context: invitesViewModel.context)
        }
        .snapshotPreferences(expect: invitesViewModel.context.$viewState.map { state in
            !state.visibleJoinedMembers.isEmpty
        })
        .previewDisplayName("Invites")
        
        NavigationStack {
            RoomMembersListScreen(context: adminViewModel.context)
        }
        .snapshotPreferences(expect: adminViewModel.context.$viewState.map { state in
            state.canBanUsers == true
        })
        .previewDisplayName("Admin: Members")
        
        NavigationStack {
            RoomMembersListScreen(context: bannedViewModel.context)
        }
        .snapshotPreferences(expect: bannedViewModel.context.$viewState.map { state in
            state.canBanUsers == true
        })
        .previewDisplayName("Admin: Banned")
        
        NavigationStack {
            RoomMembersListScreen(context: emptyBannedViewModel.context)
                .onAppear { emptyBannedViewModel.context.searchQuery = "Dan" }
        }
        .snapshotPreferences(expect: emptyBannedViewModel.context.$viewState.map(\.shouldShowEmptyState))
        .previewDisplayName("Empty Search")
    }
    
    static func makeViewModel(withInvites: Bool = false,
                              withBanned: Bool = true,
                              isAdmin: Bool = false,
                              initialMode: RoomMembersListScreenMode = .members,
                              searchQuery: String = "") -> RoomMembersListScreenViewModel {
        let mockAdmin = RoomMemberProxyMock.mockAdmin
        
        let ownUserID = isAdmin ? mockAdmin.userID : RoomMemberProxyMock.mockMe.userID
        
        var members: [RoomMemberProxyMock] = [
            .mockAlice,
            .mockBob,
            .mockCharlie,
            mockAdmin,
            .mockCreator,
            .mockOwner,
            .mockModerator
        ]
        
        if withBanned {
            members.append(contentsOf: RoomMemberProxyMock.mockBanned)
        }
        
        if withInvites {
            members.append(.mockInvited)
        }
        
        let clientProxyMock = ClientProxyMock(.init())
        clientProxyMock.userIdentityForFallBackToServerClosure = { userID, _ in
            let identity = switch userID {
            case RoomMemberProxyMock.mockAlice.userID:
                UserIdentityProxyMock(configuration: .init(verificationState: .verified))
            case RoomMemberProxyMock.mockBob.userID:
                UserIdentityProxyMock(configuration: .init(verificationState: .verificationViolation))
            default:
                UserIdentityProxyMock(configuration: .init())
            }
            
            return .success(identity)
        }
        
        return RoomMembersListScreenViewModel(initialMode: initialMode,
                                              userSession: UserSessionMock(.init(clientProxy: clientProxyMock)),
                                              roomProxy: JoinedRoomProxyMock(.init(name: "Some room",
                                                                                   members: members,
                                                                                   ownUserID: ownUserID,
                                                                                   powerLevelsConfiguration: .init(canUserInvite: false))),
                                              userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                              analytics: ServiceLocator.shared.analytics)
    }
}
