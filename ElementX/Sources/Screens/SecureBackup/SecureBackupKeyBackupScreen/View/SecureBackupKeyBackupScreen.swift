//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct SecureBackupKeyBackupScreen: View {
    @ObservedObject var context: SecureBackupKeyBackupScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog {
            mainContent
        } bottomContent: {
            Button(role: .destructive) {
                context.send(viewAction: .toggleBackup)
            } label: {
                Text(L10n.screenChatBackupKeyBackupActionDisable)
            }
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.secureBackupKeyBackupScreen.deleteKeyStorage)
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .interactiveDismissDisabled()
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
    }
    
    @ViewBuilder
    private var mainContent: some View {
        switch context.viewState.mode {
        case .disableBackup:
            disableBackupSection
        }
    }
        
    private var disableBackupSection: some View {
        VStack(spacing: 24) {
            VStack(spacing: 16) {
                BigIcon(icon: \.error, style: .alertSolid)
                
                VStack(spacing: 8) {
                    Text(L10n.screenKeyBackupDisableTitle)
                        .foregroundColor(.compound.textPrimary)
                        .font(.compound.headingMDBold)
                        .multilineTextAlignment(.center)
                    
                    Text(L10n.screenKeyBackupDisableDescription)
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodyMD)
                        .multilineTextAlignment(.center)
                }
            }
            
            VStack(alignment: .leading, spacing: 4) {
                VisualListItem(title: L10n.screenKeyBackupDisableDescriptionPoint1,
                               position: .top) {
                    CompoundIcon(\.close, size: .small, relativeTo: .body)
                        .foregroundColor(.compound.iconCriticalPrimary)
                }
                
                VisualListItem(title: L10n.screenKeyBackupDisableDescriptionPoint2(InfoPlistReader.main.productionAppName),
                               position: .bottom) {
                    CompoundIcon(\.close, size: .small, relativeTo: .body)
                        .foregroundColor(.compound.iconCriticalPrimary)
                }
            }
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }
    }
}

// MARK: - Previews

struct SecureBackupKeyBackupScreen_Previews: PreviewProvider, TestablePreview {
    static let setupViewModel = viewModel(keyBackupState: .enabled)
    
    static var previews: some View {
        NavigationStack {
            SecureBackupKeyBackupScreen(context: setupViewModel.context)
        }
        .previewDisplayName("Set up")
    }
    
    static func viewModel(keyBackupState: SecureBackupKeyBackupState) -> SecureBackupKeyBackupScreenViewModelType {
        let backupController = SecureBackupControllerMock()
        backupController.underlyingKeyBackupState = CurrentValueSubject<SecureBackupKeyBackupState, Never>(keyBackupState).asCurrentValuePublisher()
        
        return SecureBackupKeyBackupScreenViewModel(secureBackupController: backupController,
                                                    userIndicatorController: nil)
    }
}
