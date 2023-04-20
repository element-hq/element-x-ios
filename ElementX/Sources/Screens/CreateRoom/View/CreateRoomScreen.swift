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

struct CreateRoomScreen: View {
    @ObservedObject var context: CreateRoomViewModel.Context
    
    var body: some View {
        mainContent
            .scrollContentBackground(.hidden)
            .background(Color.element.formBackground.ignoresSafeArea())
            .navigationTitle(L10n.screenCreateRoomTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    createButton
                }
            }
    }
    
    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(alignment: .center, spacing: 24) {
            Form {
                roomSection
                topicSection
            }
            selectedUsersSection
            Spacer()
            Form {
                securitySection
            }
        }
    }
    
    private var roomSection: some View {
        Section {
            TextField(L10n.screenCreateRoomRoomNameLabel,
                      text: $context.roomName,
                      prompt: Text(L10n.screenCreateRoomRoomNamePlaceholder).compoundFormTextFieldPlaceholder(),
                      axis: .horizontal)
                .textFieldStyle(.compoundForm)
        } header: {
            Text(L10n.screenCreateRoomRoomNameLabel)
                .compoundFormSectionFooter()
        }
        .compoundFormSection()
    }
    
    private var topicSection: some View {
        Section {
            TextField(L10n.screenCreateRoomTopicLabel,
                      text: $context.roomTopic,
                      prompt: Text(L10n.screenCreateRoomTopicPlaceholder).compoundFormTextFieldPlaceholder(),
                      axis: .vertical)
                .lineLimit(3, reservesSpace: false)
                .textFieldStyle(.compoundForm)
        } header: {
            Text(L10n.screenCreateRoomTopicLabel)
                .compoundFormSectionFooter()
        }
        .formSectionStyle()
    }
    
    @ScaledMetric private var cellWidth: CGFloat = 64
    private var selectedUsersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 28) {
                ForEach(context.viewState.selectedUsers, id: \.userID) { user in
                    InviteUsersSelectedItem(user: user, imageProvider: context.imageProvider) {
                        deselect(user)
                    }
                    .frame(width: cellWidth)
                }
            }
            .padding(.horizontal, 18)
        }
    }
    
    private var securitySection: some View {
        Section {
            Button(action: selectPrivate) {
                Label(L10n.screenCreateRoomPrivateOptionTitle, systemImage: "lock.shield")
            }
            .buttonStyle(FormButtonStyle(accessory: .navigationLink))
            Button(action: selectPrivate) {
                Label(L10n.screenCreateRoomPublicOptionTitle, systemImage: "exclamationmark.shield")
            }
            .buttonStyle(FormButtonStyle(accessory: .navigationLink))
        } header: {
            Text("SECURITY")
        }
        .formSectionStyle()
    }
    
    private var createButton: some View {
        Button { context.send(viewAction: .createRoom) } label: {
            Text(L10n.actionCreate)
        }
        .disabled(!context.viewState.canCreateRoom)
    }
    
    private func selectPrivate() {
        context.send(viewAction: .selectPrivateRoom)
    }
    
    private func selectPublic() {
        context.send(viewAction: .selectPublicRoom)
    }
    
    private func deselect(_ user: UserProfile) {
        context.send(viewAction: .deselectUser(user))
    }
}

// MARK: - Previews

struct CreateRoom_Previews: PreviewProvider {
    static let viewModel = CreateRoomViewModel(selectedUsers: [.mockAlice, .mockBob, .mockCharlie])
    
    static var previews: some View {
        NavigationView {
            CreateRoomScreen(context: viewModel.context)
        }
    }
}
