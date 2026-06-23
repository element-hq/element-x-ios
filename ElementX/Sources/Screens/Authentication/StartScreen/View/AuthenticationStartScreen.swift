//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The screen shown at the beginning of the onboarding flow.
struct AuthenticationStartScreen: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    let context: AuthenticationStartScreenViewModel.Context
    
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
                versionText
                    .font(.compound.bodySM)
                    .foregroundColor(.compound.textSecondary)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom)
                    .onTapGesture(count: 7) {
                        context.send(viewAction: .reportProblem)
                    }
                    .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.appVersion)
            }
        }
        .navigationBarHidden(true)
        .background {
            AuthenticationStartScreenBackgroundImage()
        }
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            Spacer()
            
            if verticalSizeClass == .regular {
                Spacer()
                
                AuthenticationStartLogo(isOnGradient: !context.viewState.hideBrandChrome)
            }
            
            Spacer()
            
            if !context.viewState.hideBrandChrome {
                VStack(spacing: 24) {
                    VStack(spacing: 8) {
                        Text(L10n.screenOnboardingWelcomeTitle)
                            .font(.compound.headingLGBold)
                            .foregroundColor(.compound.textPrimary)
                            .multilineTextAlignment(.center)
                    }
                    trustPills
                }
                .padding()
                .fixedSize(horizontal: false, vertical: true)
            }
            
            Spacer()
        }
        .padding(.bottom)
        .padding(.horizontal, 16)
        .readableFrame()
    }

    /// On-brand trust signals shown under the welcome message.
    private var trustPills: some View {
        VStack(spacing: 8) {
            TrustPill(systemImage: "lock.fill", title: L10n.screenOnboardingTrustEncrypted)
        }
    }

    /// The main action buttons.
    var buttons: some View {
        VStack(spacing: 16) {
            if context.viewState.showQRCodeLoginButton {
                Button { context.send(viewAction: .loginWithQR) } label: {
                    Label(L10n.screenOnboardingSignInWithQrCode, icon: \.qrCode)
                }
                .buttonStyle(.compound(.primary))
                .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.signInWithQr)
            }
            
            Button { context.send(viewAction: .login) } label: {
                Text(context.viewState.loginButtonTitle)
            }
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.signIn)
            
            if context.viewState.showCreateAccountButton {
                Button { context.send(viewAction: .register) } label: {
                    Text(L10n.screenCreateAccountTitle)
                }
                .buttonStyle(.compound(.tertiary))
            }
        }
        .padding(.horizontal, verticalSizeClass == .compact ? 128 : 24)
        .readableFrame()
    }
    
    var versionText: Text {
        // Let's not deal with snapshotting a changing version string.
        let shortVersionString = ProcessInfo.isRunningTests ? "0.0.0" : InfoPlistReader.main.bundleShortVersionString
        return Text(L10n.screenOnboardingAppVersion(shortVersionString))
    }
}

/// A single capsule "trust" chip — icon + short claim, frosted so it reads on the launch gradient.
private struct TrustPill: View {
    let systemImage: String
    let title: String

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: systemImage)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.iconSuccessPrimary)
            Text(title)
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.compound.textPrimary)
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 16)
        .background(.ultraThinMaterial, in: Capsule())
        .overlay(Capsule().strokeBorder(.white.opacity(0.15), lineWidth: 0.5))
    }
}

// MARK: - Previews

struct AuthenticationStartScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let provisionedViewModel = makeViewModel(provisionedServerName: "example.com")
    
    static var previews: some View {
        AuthenticationStartScreen(context: viewModel.context)
            .previewDisplayName("Default")
        AuthenticationStartScreen(context: provisionedViewModel.context)
            .previewDisplayName("Provisioned")
    }
    
    static func makeViewModel(provisionedServerName: String? = nil) -> AuthenticationStartScreenViewModel {
        AuthenticationStartScreenViewModel(authenticationService: AuthenticationService.mock,
                                           provisioningParameters: provisionedServerName.map { .init(accountProvider: $0, loginHint: nil) },
                                           isBugReportServiceEnabled: true,
                                           appSettings: ServiceLocator.shared.settings,
                                           userIndicatorController: UserIndicatorControllerMock())
    }
}
