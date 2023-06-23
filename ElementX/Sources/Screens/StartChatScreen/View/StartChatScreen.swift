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

struct StartChatScreen: View {
    @ObservedObject var context: StartChatScreenViewModel.Context
    
    var body: some View {
        Form {
            if !context.viewState.isSearching {
                mainContent
            } else {
                searchContent
            }
        }
        .compoundForm()
        .track(screen: .startChat)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(L10n.actionStartChat)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                closeButton
            }
        }
        .disableInteractiveDismissOnSearch()
        .dismissSearchOnDisappear()
        .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: L10n.commonSearchForSomeone)
        .compoundSearchField()
        .alert(item: $context.alertInfo)
    }

    // MARK: - Private

    /// The content shown in the form when the search query is empty.
    @ViewBuilder
    private var mainContent: some View {
        createRoomSection
        inviteFriendsSection
        usersSection
    }
    
    /// The content shown in the form when a search query has been entered.
    @ViewBuilder
    private var searchContent: some View {
        if context.viewState.hasEmptySearchResults {
            noResultsContent
        } else {
            usersSection
        }
    }
    
    private var createRoomSection: some View {
        Section {
            Button(action: createRoom) {
                Label(L10n.screenCreateRoomActionCreateRoom, systemImage: "person.3")
                    .imageScale(.small)
            }
            .buttonStyle(FormButtonStyle(accessory: .navigationLink))
        }
        .compoundFormSection()
    }
    
    private var inviteFriendsSection: some View {
        Section {
            MatrixUserShareLink(userID: context.viewState.userID) {
                Label(L10n.actionInvitePeopleToApp(InfoPlistReader.main.bundleDisplayName), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(FormButtonStyle())
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.inviteFriends)
        }
        .compoundFormSection()
    }
    
    @ViewBuilder
    private var usersSection: some View {
        if !context.viewState.usersSection.users.isEmpty {
            Section {
                ForEach(context.viewState.usersSection.users, id: \.userID) { user in
                    Button { context.send(viewAction: .selectUser(user)) } label: {
                        UserProfileCell(user: user, membership: nil, imageProvider: context.imageProvider)
                    }
                    .buttonStyle(FormButtonStyle())
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
    
    private var noResultsContent: some View {
        Text(L10n.commonNoResults)
            .font(.compound.bodyLG)
            .foregroundColor(.compound.textSecondary)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.searchNoResults)
    }
    
    private var closeButton: some View {
        Button(L10n.actionCancel, action: close)
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.closeStartChat)
    }
    
    private func createRoom() {
        context.send(viewAction: .createRoom)
    }
    
    private func close() {
        context.send(viewAction: .close)
    }
}

// MARK: - Previews

struct StartChatScreen_Previews: PreviewProvider {
    static let viewModel = {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        let userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.fetchSuggestionsReturnValue = .success([.mockAlice])
        userDiscoveryService.searchProfilesWithReturnValue = .success([.mockAlice])
        let viewModel = StartChatScreenViewModel(userSession: userSession,
                                                 appSettings: ServiceLocator.shared.settings,
                                                 analytics: ServiceLocator.shared.analytics,
                                                 userIndicatorController: nil,
                                                 userDiscoveryService: userDiscoveryService)
        return viewModel
    }()
    
    static var previews: some View {
        NavigationView {
            StartChatScreen(context: viewModel.context)
        }
    }
}
