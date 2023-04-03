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

struct InviteUsersInRoomScreen: View {
    @ObservedObject var context: InviteUsersInRoomViewModel.Context
    
    var body: some View {
        VStack {
            if !context.viewState.selectedUsers.isEmpty {
                selectedUsersSection
            }
            Form {
                usersSection
            }
        }
        .scrollContentBackground(.hidden)
        .background(Color.element.formBackground.ignoresSafeArea())
        .navigationTitle(L10n.screenCreateRoomActionInvitePeople)
        .navigationBarTitleDisplayMode(.inline)
        .navigationBarBackButtonHidden(true)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                backButton
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                nextButton
            }
        }
        .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: L10n.commonSearchForSomeone)
        .alert(item: $context.alertInfo) { $0.alert }
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
    
    private var noResultsContent: some View {
        Text(L10n.commonNoResults)
            .font(.element.body)
            .foregroundColor(.element.tertiaryContent)
            .frame(maxWidth: .infinity)
            .listRowBackground(Color.clear)
            .accessibilityIdentifier(A11yIdentifiers.startChatScreen.searchNoResults)
    }
    
    private var usersSection: some View {
        Section {
            ForEach(context.viewState.usersSection.users, id: \.userID) { user in
                Button { context.send(viewAction: .selectUser(user)) } label: {
                    SelectableUserCell(user: user,
                                       selected: context.viewState.selectedUsers.contains { $0.userID == user.userID },
                                       imageProvider: context.imageProvider)
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
    
    private var selectedUsersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 28) {
                ForEach(context.viewState.selectedUsers, id: \.userID) { user in
                    SelectedInvitedUserItem(user: user, imageProvider: context.imageProvider) {
                        deselect(user)
                    }
                    .frame(width: 64, height: 90)
                }
            }
        }
        .frame(height: 90)
        .padding(.horizontal, 18)
    }
    
    private var backButton: some View {
        Button { context.send(viewAction: .close) } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                Text(L10n.actionBack)
            }
        }
    }
    
    private var nextButton: some View {
        Button { context.send(viewAction: .proceed) } label: {
            Text(context.viewState.selectedUsers.isEmpty ? L10n.actionSkip : L10n.actionNext)
        }
    }
    
    private func deselect(_ user: UserProfile) {
        context.send(viewAction: .deselectUser(user))
    }
}

// MARK: - Previews

struct InviteUsersInRoom_Previews: PreviewProvider {
    static var previews: some View {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        let viewModel = InviteUsersInRoomViewModel(userSession: userSession)
        NavigationView {
            InviteUsersInRoomScreen(context: viewModel.context)
                .tint(.element.accent)
        }
    }
}
