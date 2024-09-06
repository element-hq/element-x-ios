//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
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
        .compoundList()
        .track(screen: .CreateRoom)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(L10n.screenCreateRoomTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .readFrame($frame)
        .alert(item: $context.alertInfo)
    }
    
    private var roomSection: some View {
        Section {
            HStack(alignment: .center, spacing: 16) {
                roomAvatarButton
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.screenCreateRoomRoomNameLabel.uppercased())
                        .padding(.leading, ListRowPadding.horizontal)
                        .compoundListSectionHeader()
                    
                    TextField(L10n.screenCreateRoomRoomNameLabel,
                              text: $context.roomName,
                              prompt: Text(L10n.commonRoomNamePlaceholder).foregroundColor(.compound.textPlaceholder),
                              axis: .horizontal)
                        .focused($focus, equals: .name)
                        .accessibilityIdentifier(A11yIdentifiers.createRoomScreen.roomName)
                        .padding(.horizontal, ListRowPadding.horizontal)
                        .padding(.vertical, ListRowPadding.vertical)
                        .background(.compound.bgCanvasDefaultLevel1, in: RoundedRectangle(cornerRadius: 12))
                }
            }
            .listRowInsets(.init())
            .listRowBackground(Color.clear)
        }
    }
    
    private var roomAvatarButton: some View {
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
                .scaledFrame(size: 70)
                .clipShape(Circle())
            } else {
                CompoundIcon(\.takePhoto, size: .custom(36), relativeTo: .title)
                    .foregroundColor(.compound.iconSecondary)
                    .scaledFrame(size: 70, relativeTo: .title)
                    .background(.compound.bgSubtlePrimary, in: Circle())
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
    }
    
    private var topicSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.commonTopicPlaceholder),
                    kind: .textField(text: $context.roomTopic, axis: .vertical))
                .lineLimit(3, reservesSpace: false)
                .focused($focus, equals: .topic)
                .accessibilityIdentifier(A11yIdentifiers.createRoomScreen.roomTopic)
        } header: {
            Text(L10n.screenCreateRoomTopicLabel)
                .compoundListSectionHeader()
        } footer: {
            if !context.viewState.selectedUsers.isEmpty {
                selectedUsersSection
            }
        }
    }
    
    @State private var frame: CGRect = .zero
    @ScaledMetric private var invitedUserCellWidth: CGFloat = 72

    private var selectedUsersSection: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            LazyHStack(spacing: 16) {
                ForEach(context.viewState.selectedUsers, id: \.userID) { user in
                    InviteUsersScreenSelectedItem(user: user, mediaProvider: context.mediaProvider) {
                        context.send(viewAction: .deselectUser(user))
                    }
                    .frame(width: invitedUserCellWidth)
                }
            }
            .padding(.horizontal, ListRowPadding.horizontal)
            .padding(.vertical, 22)
        }
        .frame(width: frame.width)
    }
    
    private var securitySection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenCreateRoomPrivateOptionTitle,
                                    description: L10n.screenCreateRoomPrivateOptionDescription,
                                    icon: \.lock,
                                    iconAlignment: .top),
                    kind: .selection(isSelected: context.isRoomPrivate) { context.isRoomPrivate = true })
            ListRow(label: .default(title: L10n.screenCreateRoomPublicOptionTitle,
                                    description: L10n.screenCreateRoomPublicOptionDescription,
                                    icon: \.public,
                                    iconAlignment: .top),
                    kind: .selection(isSelected: !context.isRoomPrivate) { context.isRoomPrivate = false })
        } header: {
            Text(L10n.commonSecurity.uppercased())
                .compoundListSectionHeader()
        }
    }
    
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionCreate) {
                focus = nil
                context.send(viewAction: .createRoom)
            }
            .disabled(!context.viewState.canCreateRoom)
        }
    }
}

// MARK: - Previews

struct CreateRoom_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@userid:example.com"))))
        let parameters = CreateRoomFlowParameters()
        let selectedUsers: [UserProfileProxy] = [.mockAlice, .mockBob, .mockCharlie]
        
        return CreateRoomViewModel(userSession: userSession,
                                   createRoomParameters: .init(parameters),
                                   selectedUsers: .init(selectedUsers),
                                   analytics: ServiceLocator.shared.analytics,
                                   userIndicatorController: UserIndicatorControllerMock())
    }()
    
    static let emtpyViewModel = {
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@userid:example.com"))))
        let parameters = CreateRoomFlowParameters()
        return CreateRoomViewModel(userSession: userSession,
                                   createRoomParameters: .init(parameters),
                                   selectedUsers: .init([]),
                                   analytics: ServiceLocator.shared.analytics,
                                   userIndicatorController: UserIndicatorControllerMock())
    }()
    
    static var previews: some View {
        NavigationStack {
            CreateRoomScreen(context: viewModel.context)
        }
        .previewDisplayName("Create Room")
        NavigationStack {
            CreateRoomScreen(context: emtpyViewModel.context)
        }
        .previewDisplayName("Create Room without users")
    }
}
