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

import Combine
import Compound
import SwiftUI

struct SecureBackupScreen: View {
    @ObservedObject var context: SecureBackupScreenViewModel.Context
    
    var body: some View {
        Form {
            if context.viewState.keyBackupState == .unknown {
                keyBackupSection
            } else {
                keyBackupSection
                recoveryKeySection
            }
        }
        .compoundList()
        .navigationTitle(L10n.commonChatBackup)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
    }
    
    // MARK: - Private
    
    @ViewBuilder
    private var keyBackupSection: some View {
        Section {
            ListRow(kind: .custom {
                VStack(alignment: .leading, spacing: 2) {
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
            
            keyBackupButton
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
    
    @ViewBuilder
    private var keyBackupButton: some View {
        switch context.viewState.keyBackupState {
        case .enabled, .disabling:
            ListRow(label: .plain(title: L10n.screenChatBackupKeyBackupActionDisable, role: .destructive), kind: .navigationLink {
                context.send(viewAction: .keyBackup)
            })
        case .unknown, .enabling:
            ListRow(label: .plain(title: L10n.screenChatBackupKeyBackupActionEnable), kind: .navigationLink {
                context.send(viewAction: .keyBackup)
            })
        }
    }
    
    @ViewBuilder
    private var recoveryKeySection: some View {
        Section {
            switch context.viewState.recoveryKeyState {
            case .enabled:
                ListRow(label: .plain(title: L10n.screenChatBackupRecoveryActionChange),
                        kind: .navigationLink { context.send(viewAction: .recoveryKey) })
            case .disabled:
                ListRow(label: .plain(title: L10n.screenChatBackupRecoveryActionSetup),
                        details: .icon(BadgeView(size: 10)),
                        kind: .navigationLink { context.send(viewAction: .recoveryKey) })
            case .incomplete:
                ListRow(label: .plain(title: L10n.screenChatBackupRecoveryActionConfirm),
                        details: .icon(BadgeView(size: 10)),
                        kind: .navigationLink { context.send(viewAction: .recoveryKey) })
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
        switch context.viewState.recoveryKeyState {
        case .disabled:
            Text(L10n.screenChatBackupRecoveryActionSetupDescription(InfoPlistReader.main.bundleDisplayName))
        case .incomplete:
            Text(L10n.screenChatBackupRecoveryActionConfirmDescription)
        default:
            EmptyView()
        }
    }
}

// MARK: - Previews

struct SecureBackupScreen_Previews: PreviewProvider, TestablePreview {
    static let bothSetupViewModel = viewModel(keyBackupState: .enabled, recoveryKeyState: .enabled)
    static let onlyKeyBackupSetUpViewModel = viewModel(keyBackupState: .enabled, recoveryKeyState: .disabled)
    static let keyBackupDisabledViewModel = viewModel(keyBackupState: .unknown, recoveryKeyState: .disabled)
    static let recoveryIncompleteViewModel = viewModel(keyBackupState: .enabled, recoveryKeyState: .incomplete)
    
    static var previews: some View {
        Group {
            NavigationStack {
                SecureBackupScreen(context: bothSetupViewModel.context)
            }
            .previewDisplayName("Both setup")
            
            NavigationStack {
                SecureBackupScreen(context: onlyKeyBackupSetUpViewModel.context)
            }
            .previewDisplayName("Only key backup setup")
            
            NavigationStack {
                SecureBackupScreen(context: keyBackupDisabledViewModel.context)
            }
            .previewDisplayName("Key backup disabled")
            
            NavigationStack {
                SecureBackupScreen(context: recoveryIncompleteViewModel.context)
            }
            .previewDisplayName("Recovery incomplete")
        }
        .snapshot(delay: 1.0)
    }
    
    static func viewModel(keyBackupState: SecureBackupKeyBackupState,
                          recoveryKeyState: SecureBackupRecoveryKeyState) -> SecureBackupScreenViewModelType {
        let backupController = SecureBackupControllerMock()
        backupController.underlyingKeyBackupState = CurrentValueSubject<SecureBackupKeyBackupState, Never>(keyBackupState).asCurrentValuePublisher()
        backupController.underlyingRecoveryKeyState = CurrentValueSubject<SecureBackupRecoveryKeyState, Never>(recoveryKeyState).asCurrentValuePublisher()
        
        return SecureBackupScreenViewModel(secureBackupController: backupController,
                                           userIndicatorController: UserIndicatorControllerMock(),
                                           chatBackupDetailsURL: .sharedPublicDirectory)
    }
}
