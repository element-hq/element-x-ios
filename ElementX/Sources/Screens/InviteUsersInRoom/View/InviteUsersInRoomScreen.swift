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
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyHStack {
                        ForEach(context.viewState.selectedUsers, id: \.userID) { user in
                            SelectedInvitedUserItem(user: user, imageProvider: MockMediaProvider())
                        }
                    }
                }
                .frame(height: 80)
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
        }
        .searchable(text: $context.searchQuery, placement: .navigationBarDrawer(displayMode: .always), prompt: L10n.commonSearchForSomeone)
        .alert(item: $context.alertInfo) { $0.alert }
    }
    
    private var usersSection: some View {
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
    
    private var backButton: some View {
        Button { context.send(viewAction: .close) } label: {
            HStack(spacing: 8) {
                Image(systemName: "chevron.left")
                Text(L10n.actionBack)
            }
        }
    }
}

// MARK: - Previews

struct InviteUsersInRoom_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = InviteUsersInRoomViewModel()
        NavigationView {
            InviteUsersInRoomScreen(context: viewModel.context)
                .tint(.element.accent)
        }
    }
}
