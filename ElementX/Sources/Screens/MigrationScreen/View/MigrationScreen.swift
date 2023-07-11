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

import SwiftUI

struct MigrationScreen: View {
    @ObservedObject var context: MigrationScreenViewModel.Context
    
    var body: some View {
        WaitingDialog {
            content
        } bottomContent: {
            EmptyView()
        }
        .navigationBarBackButtonHidden()
    }
    
    var content: some View {
        VStack(spacing: 16) {
            ProgressView()
                .tint(.compound.iconPrimary)
                .padding(.bottom, 4)
            
            Text(L10n.screenMigrationTitle.tinting(".", color: .element.brand))
                .font(.compound.headingXLBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(L10n.screenMigrationMessage)
                .font(.compound.bodyLG)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .accessibilityIdentifier(A11yIdentifiers.migrationScreen.message)
        }
    }
}

// MARK: - Previews

struct MigrationScreen_Previews: PreviewProvider {
    static let viewModel = MigrationScreenViewModel()
    static var previews: some View {
        MigrationScreen(context: viewModel.context)
    }
}
