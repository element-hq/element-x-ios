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
        .compoundList()
        .track(screen: .StartChat)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(L10n.actionStartChat)
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
            ListRow(label: .default(title: L10n.screenCreateRoomActionCreateRoom,
                                    icon: \.plus),
                    kind: .navigationLink { context.send(viewAction: .createRoom) })
                .accessibilityIdentifier(A11yIdentifiers.startChatScreen.createRoom)
        }
    }
    
    private var inviteFriendsSection: some View {
        Section {
            ListRow(kind: .custom {
                MatrixUserShareLink(userID: context.viewState.userID) {
                    ListRowLabel.default(title: L10n.actionInvitePeopleToApp(InfoPlistReader.main.bundleDisplayName),
                                         icon: CompoundIcon(asset: Asset.Images.shareIos))
                }
            })
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.inviteFriends)
        }
    }
    
    @ViewBuilder
    private var usersSection: some View {
        if !context.viewState.usersSection.users.isEmpty {
            Section {
                ForEach(context.viewState.usersSection.users, id: \.userID) { user in
                    UserProfileListRow(user: user,
                                       membership: nil,
                                       imageProvider: context.imageProvider,
                                       kind: .button {
                                           context.send(viewAction: .selectUser(user))
                                       })
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
    
    private var noResultsContent: some View {
        Text(L10n.commonNoResults)
            .font(.compound.bodyLG)
            .foregroundColor(.compound.textSecondary)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.searchNoResults)
    }
    
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .close)
            }
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.closeStartChat)
        }
    }
}

// MARK: - Previews

struct StartChatScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider(),
                                          voiceMessageMediaManager: VoiceMessageMediaManagerMock())
        let userDiscoveryService = UserDiscoveryServiceMock()
        userDiscoveryService.fetchSuggestionsReturnValue = .success([.mockAlice])
        userDiscoveryService.searchProfilesWithReturnValue = .success([.mockAlice])
        let viewModel = StartChatScreenViewModel(userSession: userSession,
                                                 userSuggestionsEnabled: true,
                                                 analytics: ServiceLocator.shared.analytics,
                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                 userDiscoveryService: userDiscoveryService)
        return viewModel
    }()
    
    static var previews: some View {
        NavigationView {
            StartChatScreen(context: viewModel.context)
        }
    }
}
