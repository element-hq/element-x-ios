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
            .compoundForm()
            .scrollDismissesKeyboard(.immediately)
            .navigationTitle(L10n.screenCreateRoomAddPeopleTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbar }
            .disableInteractiveDismissOnSearch()
            .dismissSearchOnDisappear()
            .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: L10n.commonSearchForSomeone)
            .searchableConfiguration(hidesNavigationBar: false)
            .compoundSearchField()
            .alert(item: $context.alertInfo)
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
                    Button { context.send(viewAction: .toggleUser(user)) } label: {
                        UserProfileCell(user: user,
                                        membership: context.viewState.membershipState(user),
                                        imageProvider: context.imageProvider)
                    }
                    .disabled(context.viewState.isUserDisabled(user))
                    .buttonStyle(FormButtonStyle(accessory: .multipleSelection(isSelected: context.viewState.isUserSelected(user))))
                }
            } header: {
                if let title = context.viewState.usersSection.title {
                    Text(title)
                }
            }
            .compoundFormSection()
        } else {
            Section.empty
        }
    }
    
    @State private var frame: CGRect = .zero
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
                    withAnimation(.easeInOut) {
                        scrollView.scrollTo(id)
                    }
                }
                .padding(.horizontal, 14)
            }
        }
        .frame(width: frame.width)
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
