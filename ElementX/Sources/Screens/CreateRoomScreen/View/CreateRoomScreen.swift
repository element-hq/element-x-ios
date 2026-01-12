//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct CreateRoomScreen: View {
    @ObservedObject var context: CreateRoomScreenViewModel.Context
    @FocusState private var focus: Focus?

    private enum Focus {
        case name
        case topic
        case alias
    }
    
    private var aliasBinding: Binding<String> {
        .init(get: {
            context.viewState.aliasLocalPart
        }, set: {
            context.send(viewAction: .updateAliasLocalPart($0))
        })
    }
    
    private var roomNameBinding: Binding<String> {
        .init(get: {
            context.viewState.roomName
        }, set: {
            context.send(viewAction: .updateRoomName($0))
        })
    }
    
    var body: some View {
        Form {
            roomSection
            topicSection
            roomAccessSection
            if !context.selectedAccessType.isPrivate {
                roomAliasSection
            }
        }
        .compoundList()
        .track(screen: .CreateRoom)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(context.viewState.isSpace ? L10n.screenCreateRoomNewSpaceTitle : L10n.screenCreateRoomNewRoomTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
        .shouldScrollOnKeyboardDidShow(focus == .alias, to: Focus.alias)
    }
    
    private var roomSection: some View {
        Section {
            HStack(alignment: .center, spacing: 16) {
                roomAvatarButton
                let nameLabel = if #available(iOS 26, *) {
                    L10n.commonName
                } else {
                    L10n.commonName.uppercased()
                }
                
                VStack(alignment: .leading, spacing: 8) {
                    Text(nameLabel)
                        .padding(.leading, ListRowPadding.horizontal)
                        .compoundListSectionHeader()
                    
                    TextField(L10n.commonName,
                              text: roomNameBinding,
                              prompt: Text(L10n.screenCreateRoomNamePlaceholder).foregroundColor(.compound.textSecondary),
                              axis: .horizontal)
                        .font(.compound.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                        .tint(.compound.iconAccentTertiary)
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
            if let url = context.viewState.avatarMediaInfo?.thumbnailURL {
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
        .accessibilityIdentifier(A11yIdentifiers.createRoomScreen.roomAvatar)
        .confirmationDialog("", isPresented: $context.showAttachmentConfirmationDialog) {
            Button(L10n.actionTakePhoto) {
                context.send(viewAction: .displayCameraPicker)
            }
            Button(L10n.actionChoosePhoto) {
                context.send(viewAction: .displayMediaPicker)
            }
            .accessibilityIdentifier(A11yIdentifiers.createRoomScreen.mediaPicker)
            
            if context.viewState.avatarMediaInfo?.thumbnailURL != nil {
                Button(L10n.actionRemove, role: .destructive) {
                    context.send(viewAction: .removeImage)
                }
            }
        }
    }
    
    private var topicSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenCreateRoomTopicPlaceholder),
                    kind: .textField(text: $context.roomTopic, axis: .vertical))
                .lineLimit(3, reservesSpace: false)
                .focused($focus, equals: .topic)
                .accessibilityIdentifier(A11yIdentifiers.createRoomScreen.roomTopic)
        } header: {
            Text(L10n.screenCreateRoomTopicLabel)
                .compoundListSectionHeader()
        }
    }
    
    private var roomAccessSection: some View {
        Section {
            ForEach(context.viewState.availableAccessTypes, id: \.self) { accessType in
                CreateRoomAccessRow(access: accessType,
                                    isSelected: context.selectedAccessType == accessType) {
                    context.selectedAccessType = accessType
                }
            }
        } header: {
            Text(L10n.screenCreateRoomRoomAccessSectionTitle)
                .compoundListSectionHeader()
        }
    }
    
    private var roomAliasSection: some View {
        Section {
            EditRoomAddressListRow(aliasLocalPart: aliasBinding,
                                   serverName: context.viewState.serverName,
                                   shouldDisplayError: context.viewState.aliasErrors.errorDescription != nil)
                .focused($focus, equals: .alias)
                .id(Focus.alias)
        } header: {
            Text(L10n.screenCreateRoomRoomAddressSectionTitle)
                .compoundListSectionHeader()
        } footer: {
            VStack(alignment: .leading, spacing: 12) {
                if let errorDescription = context.viewState.aliasErrors.errorDescription {
                    Label(errorDescription, icon: \.errorSolid, iconSize: .xSmall, relativeTo: .compound.bodySM)
                        .foregroundStyle(.compound.textCriticalPrimary)
                        .font(.compound.bodySM)
                }
                Text(L10n.screenCreateRoomRoomAddressSectionFooter)
                    .compoundListSectionFooter()
                    .font(.compound.bodySM)
            }
        }
    }
    
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionCreate) {
                focus = nil
                context.send(viewAction: .createRoom)
            }
            .disabled(!context.viewState.canCreateRoom)
            .accessibilityIdentifier(A11yIdentifiers.createRoomScreen.create)
        }
    }
}

private struct CreateRoomAccessRow: View {
    let access: CreateRoomAccessType
    let isSelected: Bool
    let onSelection: () -> Void
    
    var title: String {
        switch access {
        case .public:
            L10n.screenCreateRoomRoomAccessSectionPublicOptionTitle
        case .askToJoin:
            L10n.screenCreateRoomRoomAccessSectionKnockingOptionTitle
        case .private:
            L10n.screenCreateRoomRoomAccessSectionPrivateOptionTitle
        }
    }
    
    var description: String {
        switch access {
        case .public:
            L10n.screenCreateRoomRoomAccessSectionPublicOptionDescription
        case .askToJoin:
            L10n.screenCreateRoomRoomAccessSectionKnockingOptionDescription
        case .private:
            L10n.screenCreateRoomRoomAccessSectionPrivateOptionDescription
        }
    }
    
    var icon: KeyPath<CompoundIcons, Image> {
        switch access {
        case .public:
            \.public
        case .askToJoin:
            \.userAdd
        case .private:
            \.lock
        }
    }
    
    var body: some View {
        ListRow(label: .default(title: title,
                                description: description,
                                icon: icon,
                                iconAlignment: .top),
                kind: .selection(isSelected: isSelected,
                                 action: onSelection))
    }
}

// MARK: - Previews

struct CreateRoom_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        AppSettings.resetAllSettings()
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@userid:example.com"))))
        return CreateRoomScreenViewModel(isSpace: false,
                                         userSession: userSession,
                                         analytics: ServiceLocator.shared.analytics,
                                         userIndicatorController: UserIndicatorControllerMock(),
                                         appSettings: ServiceLocator.shared.settings)
    }()
    
    static let spaceViewModel = {
        AppSettings.resetAllSettings()
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@userid:example.com"))))
        return CreateRoomScreenViewModel(isSpace: true,
                                         userSession: userSession,
                                         analytics: ServiceLocator.shared.analytics,
                                         userIndicatorController: UserIndicatorControllerMock(),
                                         appSettings: ServiceLocator.shared.settings)
    }()
    
    static let publicRoomViewModel = {
        AppSettings.resetAllSettings()
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userIDServerName: "example.org", userID: "@userid:example.com"))))
        let viewModel = CreateRoomScreenViewModel(isSpace: false,
                                                  userSession: userSession,
                                                  analytics: ServiceLocator.shared.analytics,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  appSettings: ServiceLocator.shared.settings)
        viewModel.context.selectedAccessType = .public
        return viewModel
    }()
    
    static let askToJoinViewModel = {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.knockingEnabled = true
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userIDServerName: "example.org", userID: "@userid:example.com"))))
        let viewModel = CreateRoomScreenViewModel(isSpace: false,
                                                  userSession: userSession,
                                                  analytics: ServiceLocator.shared.analytics,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  appSettings: appSettings)
        viewModel.context.selectedAccessType = .askToJoin
        return viewModel
    }()
    
    static let publicRoomInvalidAliasViewModel = {
        AppSettings.resetAllSettings()
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userIDServerName: "example.org", userID: "@userid:example.com"))))
        let viewModel = CreateRoomScreenViewModel(isSpace: false,
                                                  userSession: userSession,
                                                  analytics: ServiceLocator.shared.analytics,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  appSettings: ServiceLocator.shared.settings)
        viewModel.context.selectedAccessType = .public
        viewModel.context.send(viewAction: .updateAliasLocalPart("#:"))
        return viewModel
    }()
    
    static let publicRoomExistingAliasViewModel = {
        AppSettings.resetAllSettings()
        let clientProxy = ClientProxyMock(.init(userIDServerName: "example.org", userID: "@userid:example.com"))
        clientProxy.isAliasAvailableReturnValue = .success(false)
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        let viewModel = CreateRoomScreenViewModel(isSpace: false,
                                                  userSession: userSession,
                                                  analytics: ServiceLocator.shared.analytics,
                                                  userIndicatorController: UserIndicatorControllerMock(),
                                                  appSettings: ServiceLocator.shared.settings)
        viewModel.context.selectedAccessType = .public
        viewModel.context.send(viewAction: .updateAliasLocalPart("existing"))
        return viewModel
    }()

    static var previews: some View {
        NavigationStack {
            CreateRoomScreen(context: viewModel.context)
        }
        .previewDisplayName("Create Room")
        
        NavigationStack {
            CreateRoomScreen(context: spaceViewModel.context)
        }
        .previewDisplayName("Create Space")
        
        NavigationStack {
            CreateRoomScreen(context: publicRoomViewModel.context)
        }
        .previewDisplayName("Create Public Room")
        
        NavigationStack {
            CreateRoomScreen(context: askToJoinViewModel.context)
        }
        .previewDisplayName("Create Knockable Room")
        
        NavigationStack {
            CreateRoomScreen(context: publicRoomInvalidAliasViewModel.context)
        }
        .snapshotPreferences(expect: publicRoomInvalidAliasViewModel.context.$viewState.map { !$0.aliasErrors.isEmpty })
        .previewDisplayName("Create Public Room, invalid alias")
        
        NavigationStack {
            CreateRoomScreen(context: publicRoomExistingAliasViewModel.context)
        }
        .snapshotPreferences(expect: publicRoomExistingAliasViewModel.context.$viewState.map { !$0.aliasErrors.isEmpty })
        .previewDisplayName("Create Public Room, existing alias")
    }
}
