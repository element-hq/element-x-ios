//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import SwiftUI

struct EncryptionResetPasswordScreen: View {
    @ObservedObject var context: EncryptionResetPasswordScreenViewModel.Context
    @FocusState private var textFieldFocus
    
    var body: some View {
        FullscreenDialog {
            VStack(spacing: 16) {
                BigIcon(icon: \.lockSolid)
                
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
                context.send(viewAction: .submit)
            }
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.encryptionResetPasswordScreen.submit)
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .interactiveDismissDisabled()
        .onAppear { textFieldFocus = true }
    }
    
    @ViewBuilder
    private var passwordSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(L10n.commonPassword)
                .foregroundColor(.compound.textPrimary)
                .font(.compound.bodySMSemibold)
            
            SecureField(L10n.screenResetEncryptionPasswordPlaceholder, text: $context.password)
                .tint(.compound.iconAccentTertiary)
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.compound.bgSubtleSecondaryLevel0)
                .clipShape(RoundedRectangle(cornerRadius: 8))
                .focused($textFieldFocus)
                .submitLabel(.done)
                .onSubmit {
                    context.send(viewAction: .submit)
                }
                .accessibilityIdentifier(A11yIdentifiers.encryptionResetPasswordScreen.passwordField)
        }
    }
}

// MARK: - Previews

struct EncryptionResetPasswordScreen_Previews: PreviewProvider, TestablePreview {
    static let passwordPublisher = PassthroughSubject<String, Never>()
    static let viewModel = EncryptionResetPasswordScreenViewModel(passwordPublisher: passwordPublisher)
    static var previews: some View {
        NavigationStack {
            EncryptionResetPasswordScreen(context: viewModel.context)
        }
    }
}
