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
        mainContent
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
            .background(ViewFrameReader(frame: $frame))
    }
    
    // MARK: - Private
    
    private var mainContent: some View {
        Form {
            if !context.viewState.selectedUsers.isEmpty {
                // this is a fix for having the carousel not clipped, and inside the form, so when the search is dismissed, it wont break the design
                Section {
                    EmptyView()
                } header: {
                    selectedUsersSection
                        .textCase(.none)
                }
            }
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
                                    membership: context.viewState.membershipState(user),
                                    imageProvider: context.imageProvider)
                }
                .buttonStyle(FormButtonStyle(isDisabled: context.viewState.isUserDisabled(user),
                                             accessory: .selection(isSelected: context.viewState.isUserSelected(user))))
            }
        } header: {
            if let title = context.viewState.usersSection.title {
                Text(title)
            }
        }
        .listRowSeparator(.automatic)
        .formSectionStyle()
    }
    
    @State private var frame: CGRect = .zero
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
        .frame(width: frame.width)
    }
    
    private var nextButton: some View {
        Button { context.send(viewAction: .proceed) } label: {
            Text(context.viewState.actionText)
        }
        .disabled(context.viewState.isActionDisabled)
    }
    
    private func deselect(_ user: UserProfile) {
        context.send(viewAction: .toggleUser(user))
    }
}

// MARK: - Previews

struct InviteUsersScreen_Previews: PreviewProvider {
    static let viewModel = {
        let userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.fetchSuggestionsReturnValue = .success([.mockAlice])
        userDiscoveryService.searchProfilesWithReturnValue = .success([.mockAlice])
        return InviteUsersScreenViewModel(selectedUsers: .init([]), roomType: .draft, mediaProvider: MockMediaProvider(), userDiscoveryService: userDiscoveryService)
    }()
    
    static var previews: some View {
        NavigationView {
            InviteUsersScreen(context: viewModel.context)
                .tint(.element.accent)
        }
    }
}
