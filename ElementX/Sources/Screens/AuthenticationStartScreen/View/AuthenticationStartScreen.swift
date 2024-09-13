//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

/// The screen shown at the beginning of the onboarding flow.
struct AuthenticationStartScreen: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @ObservedObject var context: AuthenticationStartScreenViewModel.Context
    
    var body: some View {
        GeometryReader { geometry in
            VStack(alignment: .leading, spacing: 0) {
                Spacer()
                    .frame(height: UIConstants.spacerHeight(in: geometry))
                
                content
                    .frame(width: geometry.size.width)
                    .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.hidden)
                
                buttons
                    .frame(width: geometry.size.width)
                    .padding(.bottom, UIConstants.actionButtonBottomPadding)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                    .padding(.top, 8)
                
                Spacer()
                    .frame(height: UIConstants.spacerHeight(in: geometry))
            }
            .frame(maxHeight: .infinity)
            .safeAreaInset(edge: .bottom) {
                Button {
                    context.send(viewAction: .reportProblem)
                } label: {
                    Text(L10n.commonReportAProblem)
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                        .padding(.bottom)
                }
                .frame(width: geometry.size.width)
            }
        }
        .navigationBarHidden(true)
        .background {
            AuthenticationStartScreenBackgroundImage()
        }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            Spacer()
            
            if verticalSizeClass == .regular {
                Spacer()
                
                AuthenticationStartLogo(isOnGradient: true)
            }
            
            Spacer()
            
            VStack(spacing: 8) {
                Text(L10n.screenOnboardingWelcomeTitle)
                    .font(.compound.headingLGBold)
                    .foregroundColor(.compound.textPrimary)
                    .multilineTextAlignment(.center)
                Text(L10n.screenOnboardingWelcomeMessage(InfoPlistReader.main.productionAppName))
                    .font(.compound.bodyLG)
                    .foregroundColor(.compound.textSecondary)
                    .multilineTextAlignment(.center)
            }
            .padding()
            .fixedSize(horizontal: false, vertical: true)
            
            Spacer()
        }
        .padding(.bottom)
        .padding(.horizontal, 16)
        .readableFrame()
    }
    
    /// The main action buttons.
    var buttons: some View {
        VStack(spacing: 16) {
            if context.viewState.isQRCodeLoginEnabled {
                Button { context.send(viewAction: .loginWithQR) } label: {
                    Label(L10n.screenOnboardingSignInWithQrCode, icon: \.qrCode)
                }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.signInWithQr)
            }
            
            Button { context.send(viewAction: .loginManually) } label: {
                Text(context.viewState.isQRCodeLoginEnabled ? L10n.screenOnboardingSignInManually : L10n.actionContinue)
            }
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.signIn)
            
            if context.viewState.isWebRegistrationEnabled {
                Button { context.send(viewAction: .register) } label: {
                    Text(L10n.screenCreateAccountTitle)
                        .padding(14)
                }
                .buttonStyle(.compound(.plain))
            }
        }
        .padding(.horizontal, verticalSizeClass == .compact ? 128 : 24)
        .readableFrame()
    }
}

// MARK: - Previews

struct AuthenticationStartScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = AuthenticationStartScreenViewModel(webRegistrationEnabled: true)
    
    static var previews: some View {
        AuthenticationStartScreen(context: viewModel.context)
    }
}
