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
