//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct InviteUsersScreen: View {
    @ObservedObject var context: InviteUsersScreenViewModel.Context
    
    @State private var formWidth = CGFloat.zero
    
    var showTopSection: Bool {
        !context.viewState.selectedUsers.isEmpty || context.viewState.isSearching
    }
    
    var body: some View {
        mainContent
            .compoundList()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(L10n.screenCreateRoomAddPeopleTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .searchController(query: $context.searchQuery,
                              placeholder: L10n.commonSearchForSomeone,
                              showsCancelButton: false,
                              disablesInteractiveDismiss: true,
                              accessibilityFocusOnStart: true)
            .compoundSearchField()
            .alert(item: $context.alertInfo)
            .navigationBarBackButtonHidden(context.viewState.isCreatingRoom)
    }
    
    // MARK: - Private
    
    private var mainContent: some View {
        Form {
            if showTopSection {
                // this is a fix for having the carousel not clipped, and inside the form, so when the search is dismissed, it wont break the design
                Section {
                    EmptyView()
                } header: {
                    VStack(spacing: 16) {
                        selectedUsersSection
                            .textCase(.none)
                            .frame(width: formWidth)
                        
                        if context.viewState.isSearching {
                            ProgressView()
                                .frame(maxWidth: .infinity, alignment: .center)
                                .listRowBackground(Color.clear)
                        }
                    }
                }
            }
            
            if context.viewState.hasEmptySearchResults {
                noResultsContent
            } else {
                usersSection
            }
        }
        .readWidth($formWidth)
    }
    
    private var noResultsContent: some View {
        Text(L10n.commonNoResults)
            .font(.compound.bodyLG)
            .foregroundColor(.compound.textSecondary)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.searchNoResults)
    }
    
    @ViewBuilder
    private var usersSection: some View {
        if !context.viewState.usersSection.users.isEmpty {
            Section {
                ForEach(context.viewState.usersSection.users, id: \.userID) { user in
                    UserProfileListRow(user: user,
                                       membership: context.viewState.membershipState(user),
                                       mediaProvider: context.mediaProvider,
                                       kind: .multiSelection(isSelected: context.viewState.isUserSelected(user)) {
                                           context.send(viewAction: .toggleUser(user))
                                       })
                                       .disabled(context.viewState.isUserDisabled(user))
                                       .accessibilityIdentifier(A11yIdentifiers.inviteUsersScreen.userProfile)
                }
            } header: {
                if let title = context.viewState.usersSection.title {
                    Text(title)
                        .compoundListSectionHeader()
                }
            }
        } else {
            Section.empty
        }
    }
    
    @ScaledMetric private var cellWidth: CGFloat = 72

    private var selectedUsersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scrollView in
                HStack(spacing: 16) {
                    ForEach(context.viewState.selectedUsers, id: \.userID) { user in
                        InviteUsersScreenSelectedItem(user: user, mediaProvider: context.mediaProvider) {
                            deselect(user)
                        }
                        .frame(width: cellWidth)
                    }
                }
                .onChange(of: context.viewState.scrollToLastID) { _, lastAddedID in
                    guard let id = lastAddedID else { return }
                    withElementAnimation(.easeInOut) {
                        scrollView.scrollTo(id)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if !context.viewState.isCreatingRoom {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(context.viewState.actionText) {
                context.send(viewAction: .proceed)
            }
            .accessibilityIdentifier(A11yIdentifiers.inviteUsersScreen.proceed)
            .disabled(context.viewState.isActionDisabled)
        }
    }
    
    private func deselect(_ user: UserProfileProxy) {
        context.send(viewAction: .toggleUser(user))
    }
}

// MARK: - Previews

struct InviteUsersScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.searchProfilesWithReturnValue = .success([.mockAlice])
        return InviteUsersScreenViewModel(userSession: UserSessionMock(.init()),
                                          roomProxy: JoinedRoomProxyMock(.init()),
                                          isCreatingRoom: true,
                                          userDiscoveryService: userDiscoveryService,
                                          userIndicatorController: UserIndicatorControllerMock(),
                                          appSettings: ServiceLocator.shared.settings)
    }()
    
    static var previews: some View {
        NavigationStack {
            InviteUsersScreen(context: viewModel.context)
        }
    }
}
