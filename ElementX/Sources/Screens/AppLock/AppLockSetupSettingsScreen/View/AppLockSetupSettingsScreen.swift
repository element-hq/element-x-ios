//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct AppLockSetupSettingsScreen: View {
    @ObservedObject var context: AppLockSetupSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            Section {
                ListRow(label: .plain(title: L10n.screenAppLockSettingsChangePin),
                        kind: .button { context.send(viewAction: .changePINCode) })
                    .accessibilityIdentifier(A11yIdentifiers.appLockSetupSettingsScreen.changePIN)
                
                if !context.viewState.isMandatory {
                    ListRow(label: .plain(title: L10n.screenAppLockSettingsRemovePin, role: .destructive),
                            kind: .button { context.send(viewAction: .disable) })
                        .accessibilityIdentifier(A11yIdentifiers.appLockSetupSettingsScreen.removePIN)
                }
            }
            
            if context.viewState.supportsBiometrics {
                Section {
                    ListRow(label: .plain(title: context.viewState.enableBiometricsTitle),
                            kind: .toggle($context.enableBiometrics))
                        .onChange(of: context.enableBiometrics) { _ in
                            context.send(viewAction: .enableBiometricsChanged)
                        }
                }
            }
        }
        .compoundList()
        .navigationTitle(L10n.commonScreenLock)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
    }
}

// MARK: - Previews

struct AppLockSetupSettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let faceIDViewModel = AppLockSetupSettingsScreenViewModel(appLockService: AppLockServiceMock.mock(biometryType: .faceID))
    static let touchIDViewModel = AppLockSetupSettingsScreenViewModel(appLockService: AppLockServiceMock.mock(isMandatory: true, biometryType: .touchID))
    static let biometricsUnavailableViewModel = AppLockSetupSettingsScreenViewModel(appLockService: AppLockServiceMock.mock(biometryType: .none))
    
    static var previews: some View {
        NavigationStack {
            AppLockSetupSettingsScreen(context: faceIDViewModel.context)
        }
        .previewDisplayName("Face ID")
        
        NavigationStack {
            AppLockSetupSettingsScreen(context: touchIDViewModel.context)
        }
        .previewDisplayName("Touch ID (Mandatory)")
        
        NavigationStack {
            AppLockSetupSettingsScreen(context: biometricsUnavailableViewModel.context)
        }
        .previewDisplayName("PIN only")
    }
}
