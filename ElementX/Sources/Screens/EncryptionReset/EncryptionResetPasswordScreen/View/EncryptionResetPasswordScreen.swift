//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct EncryptionResetPasswordScreen: View {
    @ObservedObject var context: EncryptionResetPasswordScreenViewModel.Context
    @FocusState private var textFieldFocus
    
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
