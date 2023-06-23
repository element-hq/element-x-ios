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
    @FocusState private var focus: Focus?

    private enum Focus {
        case name
        case topic
    }

    var body: some View {
        Form {
            roomSection
            topicSection
            securitySection
        }
        .compoundForm()
        .track(screen: .createRoom)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(L10n.screenCreateRoomTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                createButton
            }
        }
        .background(ViewFrameReader(frame: $frame))
        .alert(item: $context.alertInfo)
    }
    
    @ScaledMetric private var roomIconSize: CGFloat = 70
    private var roomSection: some View {
        Section {
            HStack(alignment: .center, spacing: 16) {
                Button {
                    focus = nil
                    context.showAttachmentConfirmationDialog = true
                } label: {
                    if let url = context.viewState.avatarURL {
                        AsyncImage(url: url) { image in
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        } placeholder: {
                            ProgressView()
                        }
                        .frame(width: roomIconSize, height: roomIconSize)
                        .clipShape(Circle())
                    } else {
                        cameraImage
                    }
                }
                .buttonStyle(.plain)
                .confirmationDialog("", isPresented: $context.showAttachmentConfirmationDialog) {
                    Button(L10n.actionTakePhoto) {
                        context.send(viewAction: .displayCameraPicker)
                    }
                    Button(L10n.actionChoosePhoto) {
                        context.send(viewAction: .displayMediaPicker)
                    }
                    if context.viewState.avatarURL != nil {
                        Button(L10n.actionRemove, role: .destructive) {
                            context.send(viewAction: .removeImage)
                        }
                    }
                }
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.screenCreateRoomRoomNameLabel.uppercased())
                        .padding(.leading, FormRow.insets.leading)
                        .compoundFormSectionHeader()
                    TextField(L10n.screenCreateRoomRoomNameLabel,
                              text: $context.roomName,
                              prompt: Text(L10n.commonRoomNamePlaceholder).foregroundColor(.compound.textPlaceholder),
                              axis: .horizontal)
                        .focused($focus, equals: .name)
                        .accessibilityIdentifier(A11yIdentifiers.createRoomScreen.roomName)
                        .padding(EdgeInsets(top: 10, leading: 16, bottom: 10, trailing: 16))
                        .background(Color.element.formRowBackground)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
        }
        .compoundFormSection()
    }
    
    private var cameraImage: some View {
        Image(systemName: "camera")
            .font(.system(size: 28, weight: .semibold))
            .foregroundColor(.compound.iconSecondary)
            .frame(width: roomIconSize, height: roomIconSize)
            .background(Color.compound.bgSubtlePrimary)
            .clipShape(Circle())
    }
    
    private var topicSection: some View {
        Section {
            TextField(L10n.screenCreateRoomTopicLabel,
                      text: $context.roomTopic,
                      prompt: Text(L10n.commonTopicPlaceholder).foregroundColor(.compound.textPlaceholder),
                      axis: .vertical)
                .focused($focus, equals: .topic)
                .accessibilityIdentifier(A11yIdentifiers.createRoomScreen.roomTopic)
                .lineLimit(3, reservesSpace: false)
        } header: {
            Text(L10n.screenCreateRoomTopicLabel)
                .compoundFormSectionHeader()
        } footer: {
            if !context.viewState.selectedUsers.isEmpty {
                selectedUsersSection
            }
        }
        .compoundFormSection()
    }
    
    @State private var frame: CGRect = .zero
    @ScaledMetric private var invitedUserCellWidth: CGFloat = 72

    private var selectedUsersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(context.viewState.selectedUsers, id: \.userID) { user in
                    InviteUsersScreenSelectedItem(user: user, imageProvider: context.imageProvider) {
                        context.send(viewAction: .deselectUser(user))
                    }
                    .frame(width: invitedUserCellWidth)
                }
            }
            .padding(.init(top: 22, leading: 20, bottom: 0, trailing: 32))
        }
        .frame(width: frame.width)
    }
    
    private var securitySection: some View {
        Section {
            Picker(L10n.commonSecurity, selection: $context.isRoomPrivate) {
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.screenCreateRoomPrivateOptionTitle)
                            .font(.compound.bodyLG)
                        Text(L10n.screenCreateRoomPrivateOptionDescription)
                            .font(.compound.bodyXS)
                            .foregroundColor(.compound.textSecondary)
                    }
                } icon: {
                    Image(systemName: "lock.shield")
                }
                .tag(true)
                .labelStyle(FormRowLabelStyle(alignment: .top))
                
                Label {
                    VStack(alignment: .leading, spacing: 2) {
                        Text(L10n.screenCreateRoomPublicOptionTitle)
                            .font(.compound.bodyLG)
                        Text(L10n.screenCreateRoomPublicOptionDescription)
                            .font(.compound.bodyXS)
                            .foregroundColor(.compound.textSecondary)
                    }
                } icon: {
                    Image(systemName: "exclamationmark.shield")
                }
                .tag(false)
                .labelStyle(FormRowLabelStyle(alignment: .top))
            }
            .labelsHidden()
            .pickerStyle(.inline)
        } header: {
            Text(L10n.commonSecurity.uppercased())
                .compoundFormSectionHeader()
                .padding(.top, 40)
        }
        .listRowSeparatorTint(.compound.borderDisabled)
        .listRowBackground(Color.element.formRowBackground)
    }
    
    private var createButton: some View {
        Button {
            focus = nil
            context.send(viewAction: .createRoom)
        } label: {
            Text(L10n.actionCreate)
        }
        .disabled(!context.viewState.canCreateRoom)
    }
}

// MARK: - Previews

struct CreateRoom_Previews: PreviewProvider {
    static let viewModel = {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        let parameters = CreateRoomFlowParameters()
        let selectedUsers: [UserProfileProxy] = [.mockAlice, .mockBob, .mockCharlie]
        
        return CreateRoomViewModel(userSession: userSession,
                                   createRoomParameters: .init(parameters),
                                   selectedUsers: .init(selectedUsers),
                                   analytics: ServiceLocator.shared.analytics,
                                   userIndicatorController: nil)
    }()
    
    static let emtpyViewModel = {
        let userSession = MockUserSession(clientProxy: MockClientProxy(userID: "@userid:example.com"),
                                          mediaProvider: MockMediaProvider())
        let parameters = CreateRoomFlowParameters()
        return CreateRoomViewModel(userSession: userSession,
                                   createRoomParameters: .init(parameters),
                                   selectedUsers: .init([]),
                                   analytics: ServiceLocator.shared.analytics,
                                   userIndicatorController: nil)
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
