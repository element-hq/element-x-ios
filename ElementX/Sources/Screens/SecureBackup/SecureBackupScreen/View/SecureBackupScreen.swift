//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct SecureBackupScreen: View {
    @Bindable var context: SecureBackupScreenViewModel.Context
    
    var body: some View {
        Form {
            // Show recovery options for confirming the recovery key and
            // getting access to secrets and implicitly the key backup
            if context.viewState.recoveryState == .incomplete {
                recoveryKeySection
            } else {
                keyBackupSection
                
                // Don't show recovery options until key backup is enabled
                if context.viewState.keyBackupState != .unknown {
                    recoveryKeySection
                }
            }
        }
        .compoundList()
        .navigationTitle(L10n.commonEncryption)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var keyBackupSection: some View {
        Section {
            ListRow(kind: .custom {
                VStack(alignment: .leading, spacing: 8) {
                    Text(L10n.screenChatBackupKeyBackupTitle)
                        .font(.compound.bodyLGSemibold)
                        .foregroundColor(.compound.textPrimary)
                    
                    Text(keyBackupDescriptionWithLearnMoreLink)
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                }
                .padding(.horizontal, ListRowPadding.horizontal)
                .padding(.vertical, ListRowPadding.vertical)
                .accessibilityElement(children: .combine)
            })
            
            ListRow(label: .plain(title: L10n.screenChatBackupKeyStorageToggleTitle,
                                  description: context.viewState.keyStorageToggleDescription),
                    kind: .toggle($context.keyStorageEnabled))
                .onChange(of: context.keyStorageEnabled) { _, newValue in
                    context.send(viewAction: .keyStorageToggled(newValue))
                }
                .accessibilityIdentifier(A11yIdentifiers.secureBackupScreen.keyStorage)
        }
    }
    
    private var keyBackupDescriptionWithLearnMoreLink: AttributedString {
        let linkPlaceholder = "{link}"
        var description = AttributedString(L10n.screenChatBackupKeyBackupDescription(linkPlaceholder))
        var linkString = AttributedString(L10n.actionLearnMore)
        linkString.link = context.viewState.chatBackupDetailsURL
        linkString.bold()
        description.replace(linkPlaceholder, with: linkString)
        return description
    }
    
    private var recoveryKeySection: some View {
        Section {
            switch context.viewState.recoveryState {
            case .enabled:
                ListRow(label: .default(title: L10n.screenChatBackupRecoveryActionChange,
                                        description: L10n.screenChatBackupRecoveryActionChangeDescription,
                                        icon: \.key,
                                        iconAlignment: .top),
                        kind: .navigationLink { context.send(viewAction: .recoveryKey) })
                    .accessibilityIdentifier(A11yIdentifiers.secureBackupScreen.recoveryKey)
            case .disabled:
                ListRow(label: .default(title: L10n.screenChatBackupRecoveryActionSetup,
                                        description: L10n.screenChatBackupRecoveryActionChangeDescription,
                                        icon: \.key,
                                        iconAlignment: .top),
                        details: .icon(BadgeView(size: 10)),
                        kind: .navigationLink { context.send(viewAction: .recoveryKey) })
                    .accessibilityIdentifier(A11yIdentifiers.secureBackupScreen.recoveryKey)
            case .incomplete:
                ListRow(label: .plain(title: L10n.screenChatBackupRecoveryActionConfirm),
                        details: .icon(BadgeView(size: 10)),
                        kind: .navigationLink { context.send(viewAction: .recoveryKey) })
                    .accessibilityIdentifier(A11yIdentifiers.secureBackupScreen.recoveryKey)
            default:
                ListRow(label: .plain(title: L10n.commonLoading), details: .isWaiting(true), kind: .label)
            }
        } footer: {
            recoveryKeySectionFooter
                .compoundListSectionFooter()
        }
    }
    
    @ViewBuilder
    private var recoveryKeySectionFooter: some View {
        switch context.viewState.recoveryState {
        case .incomplete:
            Text(L10n.screenChatBackupRecoveryActionConfirmDescription)
        default:
            EmptyView()
        }
    }
}

// MARK: - Previews

struct SecureBackupScreen_Previews: PreviewProvider, TestablePreview {
    static let bothSetupViewModel = viewModel(keyBackupState: .enabled, recoveryState: .enabled)
    static let onlyKeyBackupSetUpViewModel = viewModel(keyBackupState: .enabled, recoveryState: .disabled)
    static let keyBackupDisabledViewModel = viewModel(keyBackupState: .unknown, recoveryState: .disabled)
    static let recoveryIncompleteViewModel = viewModel(keyBackupState: .enabled, recoveryState: .incomplete)
    
    static var previews: some View {
        NavigationStack {
            SecureBackupScreen(context: bothSetupViewModel.context)
        }
        .snapshotPreferences(expect: bothSetupViewModel.context.observe(\.viewState.keyBackupState).map { $0 == .enabled })
        .previewDisplayName("Both setup")
        
        NavigationStack {
            SecureBackupScreen(context: onlyKeyBackupSetUpViewModel.context)
        }
        .snapshotPreferences(expect: onlyKeyBackupSetUpViewModel.context.observe(\.viewState.keyBackupState).map { $0 == .enabled })
        .previewDisplayName("Only key backup setup")
        
        NavigationStack {
            SecureBackupScreen(context: keyBackupDisabledViewModel.context)
        }
        .snapshotPreferences(expect: keyBackupDisabledViewModel.context.observe(\.viewState.keyBackupState).map { $0 == .unknown })
        .previewDisplayName("Key backup disabled")
        
        NavigationStack {
            SecureBackupScreen(context: recoveryIncompleteViewModel.context)
        }
        .snapshotPreferences(expect: recoveryIncompleteViewModel.context.observe(\.viewState.recoveryState).map { $0 == .incomplete })
        .previewDisplayName("Recovery incomplete")
    }
    
    static func viewModel(keyBackupState: SecureBackupKeyBackupState,
                          recoveryState: SecureBackupRecoveryState) -> SecureBackupScreenViewModelType {
        let backupController = SecureBackupControllerMock()
        backupController.underlyingKeyBackupState = CurrentValueSubject<SecureBackupKeyBackupState, Never>(keyBackupState).asCurrentValuePublisher()
        backupController.underlyingRecoveryState = CurrentValueSubject<SecureBackupRecoveryState, Never>(recoveryState).asCurrentValuePublisher()
        
        return SecureBackupScreenViewModel(secureBackupController: backupController,
                                           userIndicatorController: UserIndicatorControllerMock(),
                                           chatBackupDetailsURL: .sharedPublicDirectory)
    }
}
