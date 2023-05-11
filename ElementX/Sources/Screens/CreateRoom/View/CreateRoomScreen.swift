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
            .scrollDismissesKeyboard(.immediately)
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
        Form {
            roomSection
            topicSection
            if !context.viewState.selectedUsers.isEmpty {
                selectedUsersSection
            }
            Spacer()
                .listRowBackground(Color.clear)
            securitySection
        }
    }
    
    @ScaledMetric private var roomIconSide: CGFloat = 64
    private var roomSection: some View {
        Section {
            HStack(alignment: .center, spacing: 16) {
                Image(systemName: "camera")
                    .foregroundColor(.element.secondaryContent)
                    .frame(width: roomIconSide, height: roomIconSide)
                    .background(Color.element.quinaryContent)
                    .clipShape(Circle())
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.screenCreateRoomRoomNameLabel.uppercased())
                        .font(.compound.bodySM)
                        .padding(.leading, 16)
                        .formSectionHeader()
                    TextField(L10n.screenCreateRoomRoomNameLabel,
                              text: $context.roomName,
                              prompt: Text(L10n.screenCreateRoomRoomNamePlaceholder),
                              axis: .horizontal)
                        .accessibilityIdentifier(A11yIdentifiers.createRoomScreen.roomName)
                        .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .background(Color.element.formRowBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
        }
        .formSectionStyle()
    }
    
    private var topicSection: some View {
        Section {
            TextField(L10n.screenCreateRoomTopicLabel,
                      text: $context.roomTopic,
                      prompt: Text(L10n.screenCreateRoomTopicPlaceholder),
                      axis: .vertical)
                .accessibilityIdentifier(A11yIdentifiers.createRoomScreen.roomTopic)
                .lineLimit(3, reservesSpace: false)
        } header: {
            Text(L10n.screenCreateRoomTopicLabel)
        }
        .formSectionStyle()
    }
    
    @ScaledMetric private var cellWidth: CGFloat = 64
    private var selectedUsersSection: some View {
        Section {
            ScrollView(.horizontal, showsIndicators: false) {
                LazyHStack(spacing: 28) {
                    ForEach(context.viewState.selectedUsers, id: \.userID) { user in
                        InviteUsersScreenSelectedItem(user: user, imageProvider: context.imageProvider) {
                            deselect(user)
                        }
                        .frame(width: cellWidth)
                    }
                }
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
        }
    }
    
    private var securitySection: some View {
        Section {
            Button(action: selectPrivate) {
                Label {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.screenCreateRoomPrivateOptionTitle)
                        Text(L10n.screenCreateRoomPrivateOptionDescription)
                            .font(.compound.bodyMD)
                            .foregroundColor(.element.secondaryContent)
                    }
                } icon: {
                    Image(systemName: "lock.shield")
                }
            }
            .buttonStyle(FormButtonStyle(iconAlignment: .top, accessory: .singleSelection(isSelected: context.isRoomPrivate)))
            Button(action: selectPublic) {
                Label {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(L10n.screenCreateRoomPublicOptionTitle)
                        Text(L10n.screenCreateRoomPublicOptionDescription)
                            .font(.compound.bodyMD)
                            .foregroundColor(.element.secondaryContent)
                    }
                } icon: {
                    Image(systemName: "exclamationmark.shield")
                }
            }
            .buttonStyle(FormButtonStyle(iconAlignment: .top, accessory: .singleSelection(isSelected: !context.isRoomPrivate)))
        } header: {
            Text(L10n.commonSecurity.uppercased())
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
    static let viewModel = {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        let parameters = CreateRoomVolatileParameters()
        parameters.selectedUsers = [.mockAlice, .mockBob, .mockCharlie]
        return CreateRoomViewModel(userSession: userSession, createRoomParameters: parameters)
    }()
    
    static let emtpyViewModel = {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        let parameters = CreateRoomVolatileParameters()
        return CreateRoomViewModel(userSession: userSession, createRoomParameters: parameters)
    }()
    
    static var previews: some View {
        NavigationView {
            CreateRoomScreen(context: viewModel.context)
        }
        .previewDisplayName("Create Room")
        NavigationView {
            CreateRoomScreen(context: emtpyViewModel.context)
        }
        .previewDisplayName("Create Room without users")
    }
}
