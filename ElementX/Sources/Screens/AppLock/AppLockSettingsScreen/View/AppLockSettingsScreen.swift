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

import Compound
import SwiftUI

struct AppLockSettingsScreen: View {
    @ObservedObject var context: AppLockSettingsScreenViewModel.Context
    
    var body: some View {
        Form {
            Section {
                ListRow(label: .plain(title: UntranslatedL10n.screenAppLockSettingsChangePin),
                        kind: .button { context.send(viewAction: .changePINCode) })
                ListRow(label: .plain(title: UntranslatedL10n.screenAppLockSettingsRemovePin, role: .destructive),
                        kind: .button { context.send(viewAction: .disable) })
            }
            
            if context.viewState.supportsBiometry {
                Section {
                    ListRow(label: .plain(title: context.viewState.enableBiometryTitle),
                            kind: .toggle($context.enableBiometrics))
                        .onChange(of: context.enableBiometrics) { _ in
                            context.send(viewAction: .enableBiometricsChanged)
                        }
                }
            }
        }
        .compoundList()
        .navigationTitle(UntranslatedL10n.commonScreenLock)
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
    }
}

// MARK: - Previews

struct AppLockSettingsScreen_Previews: PreviewProvider, TestablePreview {
    static let faceIDViewModel = AppLockSettingsScreenViewModel(appLockService: AppLockServiceMock.mock(biometryType: .faceID))
    static let touchIDViewModel = AppLockSettingsScreenViewModel(appLockService: AppLockServiceMock.mock(biometryType: .touchID))
    static let biometricsUnavailableViewModel = AppLockSettingsScreenViewModel(appLockService: AppLockServiceMock.mock(biometryType: .none))
    
    static var previews: some View {
        NavigationStack {
            AppLockSettingsScreen(context: faceIDViewModel.context)
        }
        .previewDisplayName("Face ID")
        
        NavigationStack {
            AppLockSettingsScreen(context: touchIDViewModel.context)
        }
        .previewDisplayName("Touch ID")
        
        NavigationStack {
            AppLockSettingsScreen(context: biometricsUnavailableViewModel.context)
        }
        .previewDisplayName("No Biometrics")
    }
}
