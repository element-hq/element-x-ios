//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct SecurityAndPrivacyScreen: View {
    @ObservedObject var context: SecurityAndPrivacyScreenViewModel.Context
    
    var body: some View {
        Form {
            roomAccessSection
            encryptionSection
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
        } header: {
            Text(L10n.screenSecurityAndPrivacyRoomAccessSectionTitle)
                .compoundListSectionHeader()
        }
    }
    
    @ViewBuilder
    private var encryptionSection: some View {
        let encryptionBinding = Binding<Bool>(get: {
            context.desiredSettings.isEncryptionEnabled
        }, set: { newValue in
            context.send(viewAction: .tryUpdatingEncryption(newValue))
        })
        
        Section {
            ListRow(label: .plain(title: L10n.screenSecurityAndPrivacyEncryptionToggleTitle),
                    kind: .toggle(encryptionBinding))
                // We don't allow editing the encryption state if the current setting on the server is `enabled`
                .disabled(context.viewState.currentSettings.isEncryptionEnabled)
        } header: {
            Text(L10n.screenSecurityAndPrivacyEncryptionSectionTitle)
                .compoundListSectionHeader()
        } footer: {
            Text(L10n.screenSecurityAndPrivacyEncryptionSectionFooter)
                .compoundListSectionFooter()
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionSave) {
                context.send(viewAction: .save)
            }
            .disabled(!context.viewState.hasChanges)
        }
    }
}

// MARK: - Previews

// TODO: Add back TestablePreview, this is WIP so running preview tests for it is not necessary
struct SecurityAndPrivacyScreen_Previews: PreviewProvider {
    static let inviteOnlyViewModel = SecurityAndPrivacyScreenViewModel(roomProxy: JoinedRoomProxyMock(.init(joinRule: .invite)))
    
    static var previews: some View {
        NavigationStack {
            SecurityAndPrivacyScreen(context: inviteOnlyViewModel.context)
        }
    }
}
