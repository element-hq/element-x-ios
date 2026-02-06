//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SecurityAndPrivacyScreen: View {
    @ObservedObject var context: SecurityAndPrivacyScreenViewModel.Context
    
    var body: some View {
        Form {
            if context.viewState.canEditJoinRule {
                roomAccessSection
            }
            
            if context.desiredSettings.accessType.isAddressRequired, context.viewState.canEditAddress {
                visibilitySection
                if let canonicalAlias = context.viewState.canonicalAlias {
                    addressSection(canonicalAlias: canonicalAlias)
                } else {
                    addAddressSection
                }
            }
            
            if !context.viewState.isSpace {
                if context.viewState.canEnableEncryption {
                    encryptionSection
                }
                if context.viewState.canEditHistoryVisibility {
                    historySection
                }
            }
        }
        .compoundList()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(L10n.screenSecurityAndPrivacyTitle)
        .navigationBarBackButtonHidden(!context.viewState.isSaveDisabled)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
    }
    
    private var roomAccessSection: some View {
        Section {
            ListRow(label: .default(title: L10n.screenSecurityAndPrivacyRoomAccessAnyoneOptionTitle,
                                    description: L10n.screenSecurityAndPrivacyRoomAccessAnyoneOptionDescription,
                                    icon: \.public),
                    kind: .selection(isSelected: context.desiredSettings.accessType == .anyone) { context.desiredSettings.accessType = .anyone })
            
            if context.viewState.isSpaceMembersOptionAvailable {
                ListRow(label: .default(title: L10n.screenSecurityAndPrivacyRoomAccessSpaceMembersOptionTitle,
                                        description: context.viewState.spaceMembersDescription,
                                        icon: \.space),
                        kind: .selection(isSelected: context.desiredSettings.accessType.isSpaceMembers) {
                            context.send(viewAction: .selectedSpaceMembersAccess)
                        })
                        .disabled(!context.viewState.isSpaceMembersOptionSelectable)
            }
            
            if context.viewState.currentSettings.accessType == .askToJoin {
                askToJoinOption
            }
            
            // Ask to join and askToJoin with space members can coexist if the initial setting is ask to join but the space members option is available otherwise it's either one or the other.
            if context.viewState.isAskToJoinWithSpaceMembersOptionAvailable {
                askToJoinWithSpaceMembersOption
            } else if context.viewState.isKnockingEnabled, context.viewState.currentSettings.accessType != .askToJoin {
                askToJoinOption
            }
            
            ListRow(label: .default(title: L10n.screenSecurityAndPrivacyRoomAccessInviteOnlyOptionTitle,
                                    description: L10n.screenSecurityAndPrivacyRoomAccessInviteOnlyOptionDescription,
                                    icon: \.lock),
                    kind: .selection(isSelected: context.desiredSettings.accessType == .inviteOnly) { context.desiredSettings.accessType = .inviteOnly })
        } header: {
            Text(L10n.screenSecurityAndPrivacyRoomAccessSectionHeader)
                .compoundListSectionHeader()
        } footer: {
            if context.viewState.shouldShowAccessSectionFooter {
                Text(context.viewState.strings.accessSectionFooterString)
                    .compoundListSectionFooter()
                    .environment(\.openURL, OpenURLAction { _ in
                        context.send(viewAction: .manageSpaces)
                        return .handled
                    })
            }
        }
    }
    
    private var askToJoinOption: some View {
        ListRow(label: .default(title: L10n.screenSecurityAndPrivacyAskToJoinOptionTitle,
                                description: L10n.screenSecurityAndPrivacyAskToJoinOptionDescription,
                                icon: \.userAdd),
                kind: .selection(isSelected: context.desiredSettings.accessType == .askToJoin) { context.desiredSettings.accessType = .askToJoin })
            .disabled(!context.viewState.isKnockingEnabled)
    }
    
    private var askToJoinWithSpaceMembersOption: some View {
        ListRow(label: .default(title: L10n.screenSecurityAndPrivacyAskToJoinOptionTitle,
                                description: context.viewState.askToJoinWithSpaceMembersDescription,
                                icon: \.userAdd),
                kind: .selection(isSelected: context.desiredSettings.accessType.isAskToJoinWithSpaceMembers) { context.send(viewAction: .selectedAskToJoinWithSpaceMembersAccess) })
            .disabled(!context.viewState.isAskToJoinWithSpaceMembersOptionSelectable)
    }
    
    @ViewBuilder
    private var encryptionSection: some View {
        let binding = Binding<Bool>(get: {
            context.desiredSettings.isEncryptionEnabled
        }, set: { newValue in
            context.send(viewAction: .tryUpdatingEncryption(newValue))
        })
        
        Section {
            ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyEncryptionToggleTitle),
                    kind: .toggle(binding))
                // We don't allow editing the encryption state if the current setting on the server is `enabled`
                .disabled(context.viewState.currentSettings.isEncryptionEnabled)
        } header: {
            Text(L10n.screenSecurityAndPrivacyEncryptionSectionHeader)
                .compoundListSectionHeader()
        } footer: {
            Text(L10n.screenSecurityAndPrivacyEncryptionSectionFooter)
                .compoundListSectionFooter()
        }
    }
    
    private var historySection: some View {
        Section {
            ForEach(context.viewState.availableVisibilityOptions, id: \.self) { option in
                switch option {
                case .invited:
                    ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyRoomHistorySinceInviteOptionTitle),
                            kind: .selection(isSelected: context.desiredSettings.historyVisibility == .invited) { context.desiredSettings.historyVisibility = .invited })
                case .shared:
                    ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyRoomHistorySinceSelectingOptionTitle),
                            kind: .selection(isSelected: context.desiredSettings.historyVisibility == .shared) { context.desiredSettings.historyVisibility = .shared })
                case .worldReadable:
                    ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyRoomHistoryAnyoneOptionTitle),
                            kind: .selection(isSelected: context.desiredSettings.historyVisibility == .worldReadable) { context.desiredSettings.historyVisibility = .worldReadable })
                }
            }
        } header: {
            Text(L10n.screenSecurityAndPrivacyRoomHistorySectionHeader)
                .compoundListSectionHeader()
        } footer: {
            Text(context.viewState.strings.historySectionFooterString)
                .compoundListSectionFooter()
        }
    }
    
    private var visibilitySection: some View {
        Section {
            EmptyView()
        } header: {
            Text(L10n.screenSecurityAndPrivacyRoomVisibilitySectionHeader)
                .compoundListSectionHeader()
        } footer: {
            Text(L10n.screenSecurityAndPrivacyRoomVisibilitySectionFooter)
                .compoundListSectionFooter()
        }
    }
    
    private func addressSection(canonicalAlias: String) -> some View {
        Section {
            ListRow(label: .plain(title: canonicalAlias),
                    kind: .navigationLink { context.send(viewAction: .editAddress) })
            roomDirectoryVisibilityRow
        } header: {
            Text(L10n.screenSecurityAndPrivacyRoomAddressSectionHeader)
                .compoundListSectionHeader()
        } footer: {
            Text(L10n.screenSecurityAndPrivacyRoomAddressSectionFooter)
                .compoundListSectionFooter()
        }
    }
    
    private var addAddressSection: some View {
        Section {
            ListRow(kind: .custom {
                Button {
                    context.send(viewAction: .editAddress)
                } label: {
                    Text(L10n.screenSecurityAndPrivacyAddRoomAddressAction)
                        .foregroundColor(.compound.textActionAccent)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .padding(ListRowPadding.insets)
            })
        }
    }
    
    @ViewBuilder
    private var roomDirectoryVisibilityRow: some View {
        let binding = Binding<Bool>(get: {
            context.desiredSettings.isVisibileInRoomDirectory ?? false
        }, set: { newValue in
            context.desiredSettings.isVisibileInRoomDirectory = newValue
        })
        ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyRoomDirectoryVisibilityToggleTitle,
                              description: L10n.screenSecurityAndPrivacyRoomDirectoryVisibilityToggleDescription),
                details: context.desiredSettings.isVisibileInRoomDirectory == nil ? .isWaiting(true) : nil,
                kind: context.desiredSettings.isVisibileInRoomDirectory == nil ? .label : .toggle(binding))
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if !context.viewState.isSaveDisabled {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionSave) {
                context.send(viewAction: .save)
            }
            .disabled(context.viewState.isSaveDisabled)
        }
    }
}

// MARK: - Previews

struct SecurityAndPrivacyScreen_Previews: PreviewProvider, TestablePreview {
    static let inviteOnlyViewModel = {
        AppSettings.resetAllSettings()
        return SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(members: .allMembersAsCreator,
                                                                                      joinRule: .invite)),
                                                 clientProxy: ClientProxyMock(.init()),
                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                 appSettings: AppSettings())
    }()
    
    static let publicViewModel = {
        AppSettings.resetAllSettings()
        return SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(isEncrypted: false,
                                                                                      canonicalAlias: "#room:matrix.org",
                                                                                      members: .allMembersAsCreator,
                                                                                      joinRule: .public,
                                                                                      isVisibleInPublicDirectory: true)),
                                                 clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                 appSettings: AppSettings())
    }()
    
    static let publicNoAddressViewModel = {
        AppSettings.resetAllSettings()
        return SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(isEncrypted: false,
                                                                                      members: .allMembersAsCreator,
                                                                                      joinRule: .public)),
                                                 clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                 appSettings: AppSettings())
    }()
    
    static let singleSpaceMembersViewModel = {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.spaceSettingsEnabled = true
        let space = [SpaceServiceRoom].mockSingleRoom[0]
        
        return SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(isEncrypted: false,
                                                                                      canonicalAlias: "#room:matrix.org",
                                                                                      members: .allMembersAsCreator,
                                                                                      joinRule: .restricted(rules: [.roomMembership(roomID: space.id)]),
                                                                                      isVisibleInPublicDirectory: true)),
                                                 clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org",
                                                                                    spaceServiceConfiguration: .init(joinedParentSpaces: [space]))),
                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                 appSettings: appSettings)
    }()
    
    static let multipleSpacesMembersViewModel = {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.spaceSettingsEnabled = true
        let spaces = [SpaceServiceRoom].mockJoinedSpaces
        
        return SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(isEncrypted: false,
                                                                                      canonicalAlias: "#room:matrix.org",
                                                                                      members: .allMembersAsCreator,
                                                                                      joinRule: .restricted(rules: spaces.map { .roomMembership(roomID: $0.id) }),
                                                                                      isVisibleInPublicDirectory: true)),
                                                 clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org",
                                                                                    spaceServiceConfiguration: .init(joinedParentSpaces: spaces))),
                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                 appSettings: appSettings)
    }()
    
    static let askToJoinViewModel = {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.knockingEnabled = true
        
        return SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(isEncrypted: false,
                                                                                      canonicalAlias: "#room:matrix.org",
                                                                                      members: .allMembersAsCreator,
                                                                                      joinRule: .knock,
                                                                                      isVisibleInPublicDirectory: true)),
                                                 clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                 appSettings: appSettings)
    }()
    
    static let singleAskToJoinSpaceMembersViewModel = {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.spaceSettingsEnabled = true
        appSettings.knockingEnabled = true
        let space = [SpaceServiceRoom].mockSingleRoom[0]
        
        return SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(isEncrypted: false,
                                                                                      canonicalAlias: "#room:matrix.org",
                                                                                      members: .allMembersAsCreator,
                                                                                      joinRule: .knockRestricted(rules: [.roomMembership(roomID: space.id)]),
                                                                                      isVisibleInPublicDirectory: true)),
                                                 clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org",
                                                                                    spaceServiceConfiguration: .init(joinedParentSpaces: [space]))),
                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                 appSettings: appSettings)
    }()
    
    static let multipleAskToJoinSpacesMembersViewModel = {
        AppSettings.resetAllSettings()
        let appSettings = AppSettings()
        appSettings.spaceSettingsEnabled = true
        appSettings.knockingEnabled = true
        let spaces = [SpaceServiceRoom].mockJoinedSpaces
        
        return SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(isEncrypted: false,
                                                                                      canonicalAlias: "#room:matrix.org",
                                                                                      members: .allMembersAsCreator,
                                                                                      joinRule: .knockRestricted(rules: spaces.map { .roomMembership(roomID: $0.id) }),
                                                                                      isVisibleInPublicDirectory: true)),
                                                 clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org",
                                                                                    spaceServiceConfiguration: .init(joinedParentSpaces: spaces))),
                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                 appSettings: appSettings)
    }()
    
    static let publicSpaceViewModel = {
        AppSettings.resetAllSettings()
        return SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(isSpace: true,
                                                                                      isEncrypted: false,
                                                                                      canonicalAlias: "#space:matrix.org",
                                                                                      members: .allMembersAsCreator,
                                                                                      joinRule: .public,
                                                                                      isVisibleInPublicDirectory: true)),
                                                 clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                 userIndicatorController: UserIndicatorControllerMock(),
                                                 appSettings: AppSettings())
    }()
    
    static var previews: some View {
        NavigationStack {
            SecurityAndPrivacyScreen(context: inviteOnlyViewModel.context)
        }
        .previewDisplayName("Private invite only room")
        
        NavigationStack {
            SecurityAndPrivacyScreen(context: publicViewModel.context)
        }
        .snapshotPreferences(expect: publicViewModel.context.$viewState.map { state in
            state.currentSettings.isVisibileInRoomDirectory == true
        })
        .previewDisplayName("Public room")
        
        NavigationStack {
            SecurityAndPrivacyScreen(context: publicNoAddressViewModel.context)
        }
        .previewDisplayName("Public room without address")
        
        NavigationStack {
            SecurityAndPrivacyScreen(context: singleSpaceMembersViewModel.context)
        }
        .snapshotPreferences(expect: singleSpaceMembersViewModel.context.$viewState.map { state in
            state.currentSettings.isVisibileInRoomDirectory == true
        })
        .previewDisplayName("Space members")
        
        NavigationStack {
            SecurityAndPrivacyScreen(context: multipleSpacesMembersViewModel.context)
        }
        .snapshotPreferences(expect: multipleSpacesMembersViewModel.context.$viewState.map { state in
            state.currentSettings.isVisibileInRoomDirectory == true
        })
        .previewDisplayName("Multiple Spaces members")
        
        NavigationStack {
            SecurityAndPrivacyScreen(context: askToJoinViewModel.context)
        }
        .snapshotPreferences(expect: askToJoinViewModel.context.$viewState.map { state in
            state.currentSettings.isVisibileInRoomDirectory == true
        })
        .previewDisplayName("Ask to join room")
        
        NavigationStack {
            SecurityAndPrivacyScreen(context: singleAskToJoinSpaceMembersViewModel.context)
        }
        .snapshotPreferences(expect: singleAskToJoinSpaceMembersViewModel.context.$viewState.map { state in
            state.currentSettings.isVisibileInRoomDirectory == true
        })
        .previewDisplayName("Ask to join with single space members room")
        
        NavigationStack {
            SecurityAndPrivacyScreen(context: multipleAskToJoinSpacesMembersViewModel.context)
        }
        .snapshotPreferences(expect: multipleAskToJoinSpacesMembersViewModel.context.$viewState.map { state in
            state.currentSettings.isVisibileInRoomDirectory == true
        })
        .previewDisplayName("Ask to join with multiple spaces members room")
        
        NavigationStack {
            SecurityAndPrivacyScreen(context: publicSpaceViewModel.context)
        }
        .snapshotPreferences(expect: publicSpaceViewModel.context.$viewState.map { state in
            state.currentSettings.isVisibileInRoomDirectory == true
        })
        .previewDisplayName("Public space")
    }
}
