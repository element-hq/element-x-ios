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
    @ObservedObject var context: CreateRoomViewModel.Context
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
            securitySection
            if context.viewState.isKnockingFeatureEnabled,
               !context.isRoomPrivate {
                roomAccessSection
                roomAliasSection
            }
        }
        .compoundList()
        .track(screen: .CreateRoom)
        .scrollDismissesKeyboard(.immediately)
        .navigationTitle(L10n.screenCreateRoomTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
        .shouldScrollOnKeyboardDidShow(focus == .alias, to: Focus.alias)
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
                              text: roomNameBinding,
                              prompt: Text(L10n.commonRoomNamePlaceholder).foregroundColor(.compound.textSecondary),
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
        }
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
            Text(L10n.screenCreateRoomRoomVisibilitySectionTitle)
                .compoundListSectionHeader()
        }
    }
    
    private var roomAccessSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenCreateRoomRoomAccessSectionAnyoneOptionTitle,
                                  description: L10n.screenCreateRoomRoomAccessSectionAnyoneOptionDescription),
                    kind: .selection(isSelected: !context.isKnockingOnly) { context.isKnockingOnly = false })
            ListRow(label: .plain(title: L10n.screenCreateRoomRoomAccessSectionKnockingOptionTitle,
                                  description: L10n.screenCreateRoomRoomAccessSectionKnockingOptionDescription),
                    kind: .selection(isSelected: context.isKnockingOnly) { context.isKnockingOnly = true })
        } header: {
            Text(L10n.screenCreateRoomRoomAccessSectionHeader)
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
        }
    }
}

// MARK: - Previews

struct CreateRoom_Previews: PreviewProvider, TestablePreview {
    static let viewModel = {
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userID: "@userid:example.com"))))
        let parameters = CreateRoomFlowParameters()
        
        return CreateRoomViewModel(userSession: userSession,
                                   initialParameters: parameters,
                                   analytics: ServiceLocator.shared.analytics,
                                   userIndicatorController: UserIndicatorControllerMock(),
                                   appSettings: ServiceLocator.shared.settings)
    }()
    
    static let publicRoomViewModel = {
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userIDServerName: "example.org", userID: "@userid:example.com"))))
        let parameters = CreateRoomFlowParameters(isRoomPrivate: false)
        ServiceLocator.shared.settings.knockingEnabled = true
        return CreateRoomViewModel(userSession: userSession,
                                   initialParameters: parameters,
                                   analytics: ServiceLocator.shared.analytics,
                                   userIndicatorController: UserIndicatorControllerMock(),
                                   appSettings: ServiceLocator.shared.settings)
    }()
    
    static let publicRoomInvalidAliasViewModel = {
        let userSession = UserSessionMock(.init(clientProxy: ClientProxyMock(.init(userIDServerName: "example.org", userID: "@userid:example.com"))))
        let parameters = CreateRoomFlowParameters(isRoomPrivate: false, aliasLocalPart: "#:")
        ServiceLocator.shared.settings.knockingEnabled = true
        return CreateRoomViewModel(userSession: userSession,
                                   initialParameters: parameters,
                                   analytics: ServiceLocator.shared.analytics,
                                   userIndicatorController: UserIndicatorControllerMock(),
                                   appSettings: ServiceLocator.shared.settings)
    }()
    
    static let publicRoomExistingAliasViewModel = {
        let clientProxy = ClientProxyMock(.init(userIDServerName: "example.org", userID: "@userid:example.com"))
        clientProxy.isAliasAvailableReturnValue = .success(false)
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        let parameters = CreateRoomFlowParameters(isRoomPrivate: false, aliasLocalPart: "existing")
        ServiceLocator.shared.settings.knockingEnabled = true
        return CreateRoomViewModel(userSession: userSession,
                                   initialParameters: parameters,
                                   analytics: ServiceLocator.shared.analytics,
                                   userIndicatorController: UserIndicatorControllerMock(),
                                   appSettings: ServiceLocator.shared.settings)
    }()

    static var previews: some View {
        NavigationStack {
            CreateRoomScreen(context: viewModel.context)
        }
        .previewDisplayName("Create Room")
        
        NavigationStack {
            CreateRoomScreen(context: publicRoomViewModel.context)
        }
        .previewDisplayName("Create Public Room")
        
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
