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
            if context.viewState.isSearching {
                searchResultsSection
            } else {
                createRoomSection
                inviteFriendsSection
                suggestionsSection
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.element.formBackground.ignoresSafeArea())
        .navigationTitle(ElementL10n.startChat)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                closeButton
            }
        }
        .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: ElementL10n.searchForSomeone)
        .alert(item: $context.alertInfo) { $0.alert }
    }
    
    private var createRoomSection: some View {
        Section {
            Button(action: createRoom) {
                Label(ElementL10n.createARoom, systemImage: "person.3")
            }
            .buttonStyle(FormButtonStyle(accessory: .navigationLink))
        }
        .formSectionStyle()
    }
    
    private var inviteFriendsSection: some View {
        Section {
            Button(action: inviteFriends) {
                Label(ElementL10n.inviteFriendsToElement, systemImage: "square.and.arrow.up")
            }
            .buttonStyle(FormButtonStyle())
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.inviteFriends)
        }
        .formSectionStyle()
    }
    
    private var suggestionsSection: some View {
        Section {
            ForEach(context.viewState.suggestedUsers, id: \.userId) { user in
                Button { context.send(viewAction: .selectUser(user)) } label: {
                    StartChatSuggestedUserCell(user: user, imageProvider: context.imageProvider)
                }
            }
        } header: {
            Text(ElementL10n.directRoomUserListSuggestionsTitle)
        }
        .listSectionStyle()
    }
    
    private var searchResultsSection: some View {
        Section {
            ForEach(context.viewState.searchResults, id: \.userId) { user in
                Button { context.send(viewAction: .selectUser(user)) } label: {
                    StartChatSuggestedUserCell(user: user, imageProvider: context.imageProvider)
                }
            }
        }
        .listSectionStyle()
    }
    
    private var closeButton: some View {
        Button(ElementL10n.actionCancel, action: close)
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.closeStartChat)
    }
    
    private func createRoom() {
        context.send(viewAction: .createRoom)
    }
    
    private func inviteFriends() {
        context.send(viewAction: .inviteFriends)
    }
    
    private func close() {
        context.send(viewAction: .close)
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
