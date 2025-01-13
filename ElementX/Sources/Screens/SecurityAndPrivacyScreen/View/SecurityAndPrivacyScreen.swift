//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SecurityAndPrivacyScreen: View {
    @ObservedObject var context: SecurityAndPrivacyScreenViewModel.Context
    
    var body: some View {
        Form {
            roomAccessSection
            if context.desiredSettings.accessType != .inviteOnly {
                if let canonicalAlias = context.viewState.canonicalAlias {
                    visibilitySection
                    addressSection(canonicalAlias: canonicalAlias)
                    roomDirectoryVisibilitySection
                } else {
                    publishingSection
                    addAddressSection
                }
            }
            encryptionSection
            historySection
        }
        .compoundList()
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(L10n.screenSecurityAndPrivacyTitle)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
    }
    
    private var roomAccessSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyRoomAccessInviteOnlyOptionTitle,
                                  description: L10n.screenSecurityAndPrivacyRoomAccessInviteOnlyOptionDescription),
                    kind: .selection(isSelected: context.desiredSettings.accessType == .inviteOnly) { context.desiredSettings.accessType = .inviteOnly })
            ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyAskToJoinOptionTitle,
                                  description: L10n.screenSecurityAndPrivacyAskToJoinOptionDescription),
                    kind: .selection(isSelected: context.desiredSettings.accessType == .askToJoin) { context.desiredSettings.accessType = .askToJoin })
            ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyRoomAccessAnyoneOptionTitle,
                                  description: L10n.screenSecurityAndPrivacyRoomAccessAnyoneOptionDescription),
                    kind: .selection(isSelected: context.desiredSettings.accessType == .anyone) { context.desiredSettings.accessType = .anyone })
            
            if context.viewState.currentSettings.accessType == .spaceUsers {
                ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyRoomAccessSpaceMembersOptionTitle,
                                      description: L10n.screenSecurityAndPrivacyRoomAccessSpaceMembersOptionDescription),
                        kind: .selection(isSelected: context.desiredSettings.accessType == .spaceUsers) { })
                    // This is not supported so it will always be disabled and has no handler
                    .disabled(true)
            }
        } header: {
            Text(L10n.screenSecurityAndPrivacyRoomAccessSectionHeader)
                .compoundListSectionHeader()
        }
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
                case .sinceSelection:
                    ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyRoomHistorySinceSelectingOptionTitle),
                            kind: .selection(isSelected: context.desiredSettings.historyVisibility == .sinceSelection) { context.desiredSettings.historyVisibility = .sinceSelection })
                case .anyone:
                    ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyRoomHistoryAnyoneOptionTitle),
                            kind: .selection(isSelected: context.desiredSettings.historyVisibility == .anyone) { context.desiredSettings.historyVisibility = .anyone })
                case .sinceInvite:
                    ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyRoomHistorySinceInviteOptionTitle),
                            kind: .selection(isSelected: context.desiredSettings.historyVisibility == .sinceInvite) { context.desiredSettings.historyVisibility = .sinceInvite })
                }
            }
        } header: {
            Text(L10n.screenSecurityAndPrivacyRoomHistorySectionHeader)
                .compoundListSectionHeader()
        }
    }
    
    private var visibilitySection: some View {
        Section {
            EmptyView()
        } header: {
            Text(L10n.screenSecurityAndPrivacyRoomVisibilitySectionHeader)
                .compoundListSectionHeader()
        } footer: {
            Text(L10n.screenSecurityAndPrivacyRoomVisibilitySectionFooter(context.viewState.serverName))
                .compoundListSectionFooter()
        }
    }
    
    private func addressSection(canonicalAlias: String) -> some View {
        Section {
            ListRow(label: .plain(title: canonicalAlias), kind: .navigationLink { context.send(viewAction: .editAddress) })
        } header: {
            Text(L10n.screenSecurityAndPrivacyRoomAddressSectionHeader)
                .compoundListSectionHeader()
        } footer: {
            Text(L10n.screenSecurityAndPrivacyRoomAddressSectionFooter)
                .compoundListSectionFooter()
        }
    }
    
    private var publishingSection: some View {
        Section {
            EmptyView()
        } header: {
            Text(L10n.screenSecurityAndPrivacyRoomPublishingSectionHeader)
                .compoundListSectionHeader()
        } footer: {
            Text(L10n.screenSecurityAndPrivacyRoomPublishingSectionFooter)
                .compoundListSectionFooter()
        }
    }
    
    private var addAddressSection: some View {
        Section {
            ListRow(kind: .custom {
                Button(L10n.screenSecurityAndPrivacyAddRoomAddressAction) { context.send(viewAction: .editAddress) }
                    .foregroundColor(.compound.textActionAccent)
                    .padding(ListRowPadding.insets)
            })
        }
    }
    
    @ViewBuilder
    private var roomDirectoryVisibilitySection: some View {
        let binding = Binding<Bool>(get: {
            context.desiredSettings.isVisibileInRoomDirectory ?? false
        }, set: { newValue in
            context.desiredSettings.isVisibileInRoomDirectory = newValue
        })
        
        Section {
            ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyRoomDirectoryVisibilityToggleTitle),
                    details: .isWaiting(context.desiredSettings.isVisibileInRoomDirectory == nil),
                    kind: context.desiredSettings.isVisibileInRoomDirectory == nil ? .label : .toggle(binding))
        } footer: {
            Text(L10n.screenSecurityAndPrivacyRoomDirectoryVisibilitySectionFooter(context.viewState.serverName))
                .compoundListSectionFooter()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
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
    static let inviteOnlyViewModel = SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(joinRule: .invite)),
                                                                       clientProxy: ClientProxyMock(.init()),
                                                                       userIndicatorController: UserIndicatorControllerMock())
    
    static let publicViewModel = SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(isEncrypted: false,
                                                                                                        canonicalAlias: "#room:matrix.org",
                                                                                                        joinRule: .public,
                                                                                                        isVisibleInPublicDirectory: true)),
                                                                   clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                                   userIndicatorController: UserIndicatorControllerMock())
    
    static let publicNoAddressViewModel = SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(isEncrypted: false,
                                                                                                                 joinRule: .public)),
                                                                            clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                                            userIndicatorController: UserIndicatorControllerMock())
    
    static let restrictedViewModel = SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(isEncrypted: false,
                                                                                                            canonicalAlias: "#room:matrix.org",
                                                                                                            joinRule: .restricted(rules: []),
                                                                                                            isVisibleInPublicDirectory: true)),
                                                                       clientProxy: ClientProxyMock(.init(userIDServerName: "matrix.org")),
                                                                       userIndicatorController: UserIndicatorControllerMock())
    
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
            SecurityAndPrivacyScreen(context: restrictedViewModel.context)
        }
        .snapshotPreferences(expect: restrictedViewModel.context.$viewState.map { state in
            state.currentSettings.isVisibileInRoomDirectory == true
        })
        .previewDisplayName("Restricted room")
    }
}
