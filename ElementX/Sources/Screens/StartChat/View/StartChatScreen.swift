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

import SwiftUI

struct StartChatScreen: View {
    @ObservedObject var context: StartChatViewModel.Context
    
    var body: some View {
        Form {
            if !context.viewState.isSearching {
                beforeSearchContent
            } else {
                afterSearchContent
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.element.formBackground.ignoresSafeArea())
        .navigationTitle(L10n.actionStartChat)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                closeButton
            }
        }
        .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: L10n.commonSearchForSomeone)
        .alert(item: $context.alertInfo) { $0.alert }
    }
}

private extension StartChatScreen {
    @ViewBuilder
    var beforeSearchContent: some View {
        createRoomSection
        inviteFriendsSection
        usersSection
    }
    
    @ViewBuilder
    var afterSearchContent: some View {
        if context.viewState.hasEmptySearchResults {
            noResultsContent
        } else {
            usersSection
        }
    }
    
    var createRoomSection: some View {
        Section {
            Button(action: createRoom) {
                Label(L10n.actionCreateARoom, systemImage: "person.3")
            }
            .buttonStyle(FormButtonStyle(accessory: .navigationLink))
        }
        .formSectionStyle()
    }
    
    var inviteFriendsSection: some View {
        Section {
            Button(action: inviteFriends) {
                Label(L10n.actionInviteFriendsToApp(InfoPlistReader.main.bundleDisplayName), systemImage: "square.and.arrow.up")
            }
            .buttonStyle(FormButtonStyle())
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.inviteFriends)
        }
        .formSectionStyle()
    }
    
    var usersSection: some View {
        Section {
            ForEach(context.viewState.usersSection.users, id: \.userID) { user in
                Button { context.send(viewAction: .selectUser(user)) } label: {
                    StartChatSuggestedUserCell(user: user, imageProvider: context.imageProvider)
                }
            }
        } header: {
            if let title = context.viewState.usersSection.type.title {
                Text(title)
            }
        }
        .listRowSeparator(.automatic)
        .formSectionStyle()
    }
    
    var closeButton: some View {
        Button(L10n.actionCancel, action: close)
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.closeStartChat)
    }
    
    func createRoom() {
        context.send(viewAction: .createRoom)
    }
    
    func inviteFriends() {
        context.send(viewAction: .inviteFriends)
    }
    
    func close() {
        context.send(viewAction: .close)
    }
    
    var noResultsContent: some View {
        Text(L10n.commonNoResults)
            .font(.element.body)
            .foregroundColor(.element.tertiaryContent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.searchNoResults)
    }
}

// MARK: - Previews

struct StartChat_Previews: PreviewProvider {
    static var previews: some View {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        let regularViewModel = StartChatViewModel(userSession: userSession, userIndicatorController: nil)
        NavigationView {
            StartChatScreen(context: regularViewModel.context)
                .tint(.element.accent)
        }
    }
}
