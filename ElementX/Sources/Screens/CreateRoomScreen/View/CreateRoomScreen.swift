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
            if context.viewState.canSelectSpace {
                selectSpaceSection
            }
            roomAccessSection
            if !context.viewState.roomAccessType.isVisibilityPrivate {
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
        .sheet(isPresented: $context.showSpaceSelectionSheet) {
            CreateRoomSpaceSelectionSheet(context: context)
        }
    }
    
    private var nameTextFieldShape: AnyShape {
        if #available(iOS 26, *) {
            AnyShape(ConcentricRectangle(corners: .concentric(minimum: 26)))
        } else {
            AnyShape(RoundedRectangle(cornerRadius: 12))
        }
    }
    
    private var roomSection: some View {
        Section {
            EmptyView()
        } header: {
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
                        .background(.compound.bgCanvasDefaultLevel1, in: nameTextFieldShape)
                }
            }
            .listRowInsets(.init())
            .padding(.top, 16)
        }
    }
    
    private var roomAvatarButton: some View {
        Button {
            focus = nil
            context.showAttachmentConfirmationDialog = true
        } label: {
            if let avatarImage = context.viewState.avatarImage {
                Image(uiImage: avatarImage)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .scaledFrame(size: 70, relativeTo: .title)
                    .clipShape(context.viewState.isSpace ? AnyShape(RoundedRectangle(cornerRadius: 16)) : AnyShape(Circle()))
                    .overlay(alignment: .bottomTrailing) {
                        editAvatarBadge
                            .scaledOffset(x: 12, y: 4, relativeTo: .title)
                            .accessibilityHidden(true)
                    }
            } else {
                CompoundIcon(\.takePhoto, size: .medium, relativeTo: .title)
                    .foregroundColor(.compound.iconPrimary)
                    .scaledFrame(size: 50, relativeTo: .title)
                    .background(.compound.bgCanvasDefault, in: Circle())
                    .overlay {
                        Circle()
                            .stroke(.compound.borderInteractiveSecondary, lineWidth: 1)
                    }
                    .padding(10)
                    .accessibilityHidden(true)
            }
        }
        .accessibilityLabel(L10n.a11yEditAvatar)
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
            
            if context.viewState.avatarImage != nil {
                Button(L10n.actionRemove, role: .destructive) {
                    context.send(viewAction: .removeImage)
                }
            }
        }
    }
    
    private var editAvatarBadge: some View {
        CompoundIcon(\.edit, size: .small, relativeTo: .body)
            .foregroundStyle(.compound.iconPrimary)
            .scaledPadding(5, relativeTo: .title)
            .background {
                Circle()
                    .fill(Color.compound.bgCanvasDefault)
                    .overlay {
                        Circle()
                            .inset(by: 0.5)
                            .stroke(.compound.borderInteractiveSecondary, lineWidth: 1)
                    }
            }
            .scaledPadding(3.5, relativeTo: .title)
            .background(.compound.bgSubtleSecondaryLevel0, in: Circle())
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
                                    spaceName: context.selectedSpace?.name ?? "",
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
    
    private var selectSpaceSection: some View {
        Section {
            if let selectedSpace = context.selectedSpace {
                ListRow(label: .avatar(title: selectedSpace.name,
                                       description: selectedSpace.canonicalAlias,
                                       icon: RoomAvatarImage(avatar: selectedSpace.avatar,
                                                             avatarSize: .room(on: .createRoomSelectSpace),
                                                             mediaProvider: context.mediaProvider)),
                        kind: .navigationLink {
                            context.showSpaceSelectionSheet = true
                        })
            } else {
                ListRow(label: .avatar(title: L10n.screenCreateRoomSpaceSelectionNoSpaceTitle,
                                       description: L10n.screenCreateRoomSpaceSelectionNoSpaceDescription,
                                       icon: CompoundIcon(\.homeSolid, size: .small, relativeTo: .body)
                                           .foregroundColor(.compound.iconPrimary)
                                           .scaledFrame(size: 32)
                                           .background(.compound.bgSubtleSecondary)
                                           .clipAvatar(isSpace: true, size: 32)),
                        kind: .navigationLink {
                            context.showSpaceSelectionSheet = true
                        })
            }
        } header: {
            Text(L10n.commonSpace)
                .compoundListSectionHeader()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if context.viewState.shouldShowCancelButton {
            ToolbarItem(placement: .topBarLeading) {
                ToolbarButton(role: .cancel) {
                    context.send(viewAction: .dismiss)
                }
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            ToolbarButton(role: .confirm(title: L10n.actionCreate)) {
                focus = nil
                context.send(viewAction: .createRoom)
            }
            .disabled(!context.viewState.canCreateRoom)
            .accessibilityIdentifier(A11yIdentifiers.createRoomScreen.create)
        }
    }
}

private struct CreateRoomAccessRow: View {
    let access: CreateRoomScreenAccessType
    let spaceName: String
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
        case .spaceMembers:
            L10n.screenCreateRoomRoomAccessSectionRestrictedOptionTitle
        case .askToJoinWithSpaceMembers:
            L10n.screenCreateRoomRoomAccessSectionKnockingRestrictedOptionTitle
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
        case .spaceMembers:
            L10n.screenCreateRoomRoomAccessSectionRestrictedOptionDescription(spaceName)
        case .askToJoinWithSpaceMembers:
            L10n.screenCreateRoomRoomAccessSectionKnockingRestrictedOptionDescription(spaceName)
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
        case .spaceMembers:
            \.space
        case .askToJoinWithSpaceMembers:
            \.userAdd
        }
    }
    
    var body: some View {
        ListRow(label: .default(title: title,
                                description: description,
                                icon: icon),
                kind: .selection(isSelected: isSelected,
                                 action: onSelection))
    }
}

// MARK: - Previews

struct CreateRoom_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    
    static let avatarViewModel = {
        let viewModel = makeViewModel()
        viewModel.updateAvatar(fileURL: Bundle.main.url(forResource: "preview_avatar_room", withExtension: "jpg") ?? .picturesDirectory)
        return viewModel
    }()
    
    static let spaceViewModel = makeViewModel(isSpace: true, selectionMode: nil)
    
    static let spaceWithAvatarViewModel = {
        let viewModel = makeViewModel(isSpace: true, selectionMode: nil)
        viewModel.updateAvatar(fileURL: Bundle.main.url(forResource: "preview_avatar_room", withExtension: "jpg") ?? .picturesDirectory)
        return viewModel
    }()
    
    static let publicRoomViewModel = {
        let viewModel = makeViewModel()
        viewModel.context.selectedAccessType = .public
        return viewModel
    }()
    
    static let askToJoinViewModel = {
        let viewModel = makeViewModel(isKnockingEnabled: true)
        viewModel.context.selectedAccessType = .askToJoin
        return viewModel
    }()
    
    static let publicRoomInvalidAliasViewModel = {
        let viewModel = makeViewModel()
        viewModel.context.selectedAccessType = .public
        viewModel.context.send(viewAction: .updateAliasLocalPart("#:"))
        return viewModel
    }()
    
    static let publicRoomExistingAliasViewModel = {
        let viewModel = makeViewModel(isAliasAvailable: false)
        viewModel.context.selectedAccessType = .public
        viewModel.context.send(viewAction: .updateAliasLocalPart("existing"))
        return viewModel
    }()
    
    static let selectedSpaceViewModel = makeViewModel(selectionMode: .preSelected(SpaceServiceRoom.mock(name: "Awesome Space",
                                                                                                        isSpace: true,
                                                                                                        joinRule: .invite)))
    
    static let selectedSpaceWithListViewModel = {
        let viewModel = makeViewModel()
        viewModel.context.selectedSpace = [SpaceServiceRoom].mockJoinedSpaces2.first
        return viewModel
    }()
    
    static let selectedSpaceWithAskToJoinViewModel = {
        let viewModel = makeViewModel(isKnockingEnabled: true,
                                      selectionMode: .preSelected(SpaceServiceRoom.mock(name: "Awesome Space",
                                                                                        isSpace: true,
                                                                                        joinRule: .invite)))
        viewModel.context.selectedAccessType = .askToJoinWithSpaceMembers
        return viewModel
    }()

    static var previews: some View {
        NavigationStack {
            CreateRoomScreen(context: viewModel.context)
        }
        .previewDisplayName("Create Room")
        
        NavigationStack {
            CreateRoomScreen(context: avatarViewModel.context)
        }
        .previewDisplayName("Create Room with avatar")
        .snapshotPreferences(expect: avatarViewModel.context.$viewState.map { $0.avatarImage != nil })
        
        NavigationStack {
            CreateRoomScreen(context: spaceViewModel.context)
        }
        .previewDisplayName("Create Space")
        
        NavigationStack {
            CreateRoomScreen(context: spaceWithAvatarViewModel.context)
        }
        .previewDisplayName("Create Space with avatar")
        .snapshotPreferences(expect: spaceWithAvatarViewModel.context.$viewState.map { $0.avatarImage != nil })
        
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
        
        NavigationStack {
            CreateRoomScreen(context: selectedSpaceViewModel.context)
        }
        .previewDisplayName("Create Room with already selected Space")
        
        NavigationStack {
            CreateRoomScreen(context: selectedSpaceWithListViewModel.context)
        }
        .previewDisplayName("Create Room with a selected Space from the list")
        
        NavigationStack {
            CreateRoomScreen(context: selectedSpaceWithAskToJoinViewModel.context)
        }
        .previewDisplayName("Create Knockable Room with already selected Space")
    }
    
    private static func makeViewModel(isKnockingEnabled: Bool = false,
                                      isSpace: Bool = false,
                                      selectionMode: CreateRoomScreenSpaceSelectionMode? = .editableSpacesList,
                                      isAliasAvailable: Bool = true) -> CreateRoomScreenViewModel {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.knockingEnabled = isKnockingEnabled
        
        let clientProxy = ClientProxyMock(.init(userIDServerName: "example.org",
                                                userID: "@userid:example.com"))
        clientProxy.isAliasAvailableReturnValue = .success(isAliasAvailable)
        let spaces = [SpaceServiceRoom].mockJoinedSpaces2
        clientProxy.spaceService = SpaceServiceProxyMock(.init(editableSpaces: spaces))
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        
        return CreateRoomScreenViewModel(isSpace: isSpace,
                                         spaceSelectionMode: selectionMode,
                                         shouldShowCancelButton: isSpace,
                                         userSession: userSession,
                                         analytics: ServiceLocator.shared.analytics,
                                         userIndicatorController: UserIndicatorControllerMock(),
                                         appSettings: appSettings)
    }
}
