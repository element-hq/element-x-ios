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

#warning("Move this elsewhere.")
extension ShapeStyle where Self == Color {
    static var compound: CompoundColors { Self.compound }
}

struct AppLockScreen: View {
    @ObservedObject var context: AppLockScreenViewModel.Context
    
    var body: some View {
        VStack {
            Text("The app is locked 🔒")
                .font(.compound.headingLGBold)
                .foregroundStyle(.compound.textPrimary)
            
            Button("Unlock") {
                context.send(viewAction: .submitPINCode("0000"))
            }
            .font(.compound.bodyLG)
        }
    }
}

// MARK: - Previews

struct AppLockScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = AppLockScreenViewModel(appLockService: AppLockService(keychainController: KeychainControllerMock()))
    
    static var previews: some View {
        NavigationStack {
            AppLockScreen(context: viewModel.context)
        }
    }
}
