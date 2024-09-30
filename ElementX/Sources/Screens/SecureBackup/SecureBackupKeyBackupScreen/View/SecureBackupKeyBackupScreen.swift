//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        VStack(spacing: 16) {
            HeroImage(icon: \.keyOffSolid)
            
            Text(L10n.screenKeyBackupDisableTitle)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
            
            Text(L10n.screenKeyBackupDisableDescription)
                .foregroundColor(.compound.textSecondary)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
            
            VStack(alignment: .leading, spacing: 10) {
                Label {
                    Text(L10n.screenKeyBackupDisableDescriptionPoint1)
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodyMD)
                } icon: {
                    CompoundIcon(\.close)
                        .foregroundColor(.compound.iconCriticalPrimary)
                }
                
                Label {
                    Text(L10n.screenKeyBackupDisableDescriptionPoint2(InfoPlistReader.main.bundleDisplayName))
                        .foregroundColor(.compound.textSecondary)
                        .font(.compound.bodyMD)
                } icon: {
                    CompoundIcon(\.close)
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
