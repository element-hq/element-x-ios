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

struct InviteUsersScreen: View {
    @ObservedObject var context: InviteUsersScreenViewModel.Context
    
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
                              disablesInteractiveDismiss: true)
            .compoundSearchField()
            .alert(item: $context.alertInfo)
    }
    
    // MARK: - Private
    
    private var mainContent: some View {
        GeometryReader { proxy in
            Form {
                if showTopSection {
                    // this is a fix for having the carousel not clipped, and inside the form, so when the search is dismissed, it wont break the design
                    Section {
                        EmptyView()
                    } header: {
                        VStack(spacing: 16) {
                            selectedUsersSection
                                .textCase(.none)
                                .frame(width: proxy.size.width)
                            
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
        }
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
                                       imageProvider: context.imageProvider,
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
                        InviteUsersScreenSelectedItem(user: user, imageProvider: context.imageProvider) {
                            deselect(user)
                        }
                        .frame(width: cellWidth)
                    }
                }
                .onChange(of: context.viewState.scrollToLastID) { lastAddedID in
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
        userDiscoveryService.fetchSuggestionsReturnValue = .success([.mockAlice])
        userDiscoveryService.searchProfilesWithReturnValue = .success([.mockAlice])
        return InviteUsersScreenViewModel(selectedUsers: .init([]),
                                          roomType: .draft,
                                          mediaProvider: MockMediaProvider(),
                                          userDiscoveryService: userDiscoveryService,
                                          appSettings: ServiceLocator.shared.settings,
                                          userIndicatorController: UserIndicatorControllerMock())
    }()
    
    static var previews: some View {
        NavigationView {
            InviteUsersScreen(context: viewModel.context)
        }
    }
}
