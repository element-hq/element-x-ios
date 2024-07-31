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

struct EncryptionResetPasswordScreen: View {
    @ObservedObject var context: EncryptionResetPasswordScreenViewModel.Context
    @FocusState private var focused
    
    var body: some View {
        FullscreenDialog {
            VStack(spacing: 16) {
                HeroImage(icon: \.lockSolid)
                
                Text(L10n.screenResetEncryptionPasswordTitle)
                    .foregroundColor(.compound.textPrimary)
                    .font(.compound.headingMDBold)
                    .multilineTextAlignment(.center)
                
                Text(L10n.screenResetEncryptionPasswordSubtitle)
                    .foregroundColor(.compound.textSecondary)
                    .font(.compound.bodyMD)
                    .multilineTextAlignment(.center)
                
                passwordSection
            }
            .padding(16)
        } bottomContent: {
            Button(L10n.actionResetIdentity, role: .destructive) {
                context.send(viewAction: .resetIdentity)
            }
            .buttonStyle(.compound(.primary))
        }
        .backgroundStyle(.compound.bgCanvasDefault)
        .interactiveDismissDisabled()
    }
    
    @ViewBuilder
    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.commonPassword)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodySMSemibold)
            
            SecureField(L10n.screenResetEncryptionPasswordPlaceholder, text: $context.password)
                .textContentType(.password) // Not ideal but stops random suggestions
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.compound.bgSubtleSecondaryLevel0)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .focused($focused)
                .submitLabel(.done)
                .onSubmit {
                    context.send(viewAction: .resetIdentity)
                }
        }
    }
}

// MARK: - Previews

struct EncryptionResetPasswordScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = EncryptionResetPasswordScreenViewModel()
    static var previews: some View {
        NavigationStack {
            EncryptionResetPasswordScreen(context: viewModel.context)
        }
    }
}
