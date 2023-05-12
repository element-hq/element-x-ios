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
    
    var body: some View {
        VStack {
            if !context.viewState.selectedUsers.isEmpty {
                selectedUsersSection
            }
            searchContent
        }
        .scrollContentBackground(.hidden)
        .background(Color.element.formBackground.ignoresSafeArea())
        .navigationTitle(L10n.screenCreateRoomActionInvitePeople)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                nextButton
            }
        }
        .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: L10n.commonSearchForSomeone)
        .compoundSearchField()
        .alert(item: $context.alertInfo) { $0.alert }
    }
    
    // MARK: - Private
    
    /// The content shown in the form when a search query has been entered.
    @ViewBuilder
    private var searchContent: some View {
        Form {
            if context.viewState.hasEmptySearchResults {
                noResultsContent
            } else {
                usersSection
            }
        }
    }
    
    private var noResultsContent: some View {
        Text(L10n.commonNoResults)
            .font(.compound.bodyLG)
            .foregroundColor(.element.tertiaryContent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.searchNoResults)
    }
    
    private var usersSection: some View {
        Section {
            ForEach(context.viewState.usersSection.users, id: \.userID) { user in
                Button { context.send(viewAction: .toggleUser(user)) } label: {
                    UserProfileCell(user: user,
                                    imageProvider: context.imageProvider)
                }
                .buttonStyle(FormButtonStyle(accessory: .selection(isSelected: context.viewState.isUserSelected(user))))
            }
        } header: {
            if let title = context.viewState.usersSection.title {
                Text(title)
            }
        }
        .listRowSeparator(.automatic)
        .formSectionStyle()
    }
    
    @ScaledMetric private var cellWidth: CGFloat = 64
    private var selectedUsersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            ScrollViewReader { scrollView in
                HStack(spacing: 28) {
                    ForEach(context.viewState.selectedUsers, id: \.userID) { user in
                        InviteUsersScreenSelectedItem(user: user, imageProvider: context.imageProvider) {
                            deselect(user)
                        }
                        .frame(width: cellWidth)
                    }
                }
                .onChange(of: context.viewState.scrollToLastID) { lastAddedID in
                    guard let id = lastAddedID else { return }
                    withAnimation(.easeInOut) {
                        scrollView.scrollTo(id)
                    }
                }
                .padding(.horizontal, 18)
            }
        }
    }
    
    private var nextButton: some View {
        Button { context.send(viewAction: .proceed) } label: {
            Text(context.viewState.selectedUsers.isEmpty ? L10n.actionSkip : L10n.actionNext)
        }
    }
    
    private func deselect(_ user: UserProfile) {
        context.send(viewAction: .toggleUser(user))
    }
}

// MARK: - Previews

struct InviteUsersScreen_Previews: PreviewProvider {
    static let viewModel = {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        let userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.fetchSuggestionsReturnValue = .success([.mockAlice])
        userDiscoveryService.searchProfilesWithReturnValue = .success([.mockAlice])
        return InviteUsersScreenViewModel(selectedUsers: .init([]), userSession: userSession, userDiscoveryService: userDiscoveryService)
    }()
    
    static var previews: some View {
        NavigationView {
            InviteUsersScreen(context: viewModel.context)
                .tint(.element.accent)
        }
    }
}
