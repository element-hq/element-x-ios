//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct ServerConfirmationScreen: View {
    @ObservedObject var context: ServerConfirmationScreenViewModel.Context
    
    var body: some View {
        FullscreenDialog(topPadding: UIConstants.iconTopPaddingToNavigationBar) {
            header
        } bottomContent: {
            buttons
        }
        .background()
        .backgroundStyle(.compound.bgCanvasDefault)
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
    }
    
    /// The main content of the view to be shown in a scroll view.
    var header: some View {
        VStack(spacing: 8) {
            Image(systemSymbol: .personCropCircleFill)
                .heroImage()
                .padding(.bottom, 8)
            
            Text(context.viewState.title)
                .font(.zero.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(context.viewState.message)
                .font(.zero.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
        .padding(.horizontal, 16)
    }
    
    /// The action buttons shown at the bottom of the view.
    var buttons: some View {
        VStack(spacing: 16) {
            Button { context.send(viewAction: .confirm) } label: {
                Text(L10n.actionContinue)
            }
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.serverConfirmationScreen.continue)
            .disabled(!context.viewState.canContinue)
            
            Button { context.send(viewAction: .changeServer) } label: {
                Text(L10n.screenServerConfirmationChangeServer)
                    .font(.zero.bodyLGSemibold)
                    .padding(14)
            }
            .accessibilityIdentifier(A11yIdentifiers.serverConfirmationScreen.changeServer)
        }
    }
}

// MARK: - Previews

struct ServerConfirmationScreen_Previews: PreviewProvider, TestablePreview {
    static let loginViewModel = ServerConfirmationScreenViewModel(authenticationService: MockAuthenticationService(),
                                                                  authenticationFlow: .login)
    static let registerViewModel = ServerConfirmationScreenViewModel(authenticationService: MockAuthenticationService(),
                                                                     authenticationFlow: .register)
    
    static var previews: some View {
        NavigationStack {
            ServerConfirmationScreen(context: loginViewModel.context)
                .toolbar(.visible, for: .navigationBar)
        }
        .previewDisplayName("Login")
        
        NavigationStack {
            ServerConfirmationScreen(context: registerViewModel.context)
                .toolbar(.visible, for: .navigationBar)
        }
        .previewDisplayName("Register")
    }
}
