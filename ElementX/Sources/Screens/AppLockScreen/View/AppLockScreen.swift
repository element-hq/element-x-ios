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

// Move this to Compound.
extension ShapeStyle where Self == Color {
    static var compound: CompoundColors { Self.compound }
}

// This implementation is only for development purposes.

struct AppLockScreen: View {
    @ObservedObject var context: AppLockScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog {
            VStack(spacing: 8) {
                AuthenticationIconImage(image: Image(systemSymbol: .lock))
                    .symbolVariant(.fill)
                    .padding(.bottom, 8)
                
                Text(UntranslatedL10n.screenAppLockTitle(InfoPlistReader.main.bundleDisplayName))
                    .font(.compound.headingMDBold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.compound.textPrimary)
            }
        } bottomContent: {
            Button(UntranslatedL10n.commonUnlock) {
                context.send(viewAction: .submitPINCode("0000"))
            }
            .buttonStyle(.elementAction(.xLarge))
        }
    }
}

// MARK: - Previews

// Add TestablePreview conformance once we have designs.
struct AppLockScreen_Previews: PreviewProvider {
    static let viewModel = AppLockScreenViewModel(appLockService: AppLockService(keychainController: KeychainControllerMock(),
                                                                                 appSettings: ServiceLocator.shared.settings))
    
    static var previews: some View {
        NavigationStack {
            AppLockScreen(context: viewModel.context)
        }
    }
}
