//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The screen shown at the beginning of the onboarding flow.
struct AuthenticationStartScreen: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @Bindable var context: AuthenticationStartScreenViewModel.Context
    
    var body: some View {
        if case let .welcomeBack(classicAppAccount) = context.viewState.classicAppMode,
           classicAppAccount.state.isServerSupported != false {
            AuthenticationClassicAppAccountView(context: context, classicAppAccount: classicAppAccount)
        } else {
            standardContent
        }
    }
    
    var standardContent: some View {
        // This view uses a GeometryReader instead of FullscreenDialog so its content takes the full
        // height available (after taking the buttons out of the equation) in order for the logo
        // and title to appear vertically centred and equally spaced within this content area.
        GeometryReader { geometry in
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    Spacer()
                        .frame(height: UIConstants.spacerHeight(in: geometry))
                    
                    content
                        .frame(width: geometry.size.width)
                        .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.hidden)
                    
                    buttons
                        .frame(width: geometry.size.width)
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                        .padding(.top, 8)
                    
                    Spacer()
                        .frame(height: UIConstants.spacerHeight(in: geometry))
                }
                .frame(minHeight: geometry.size.height)
            }
            .scrollBounceBehavior(.basedOnSize)
        }
        .background {
            AuthenticationStartScreenBackgroundImage()
        }
        .navigationBarHidden(context.viewState.classicAppMode == nil)
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
    }
    
    var content: some View {
        VStack(spacing: 0) {
            Spacer()
            
            if verticalSizeClass == .regular {
                Spacer()
                
                AuthenticationStartLogo(hideBrandChrome: context.viewState.hideBrandChrome,
                                        isOnGradient: !context.viewState.hideBrandChrome)
            }
            
            Spacer()
            
            if !context.viewState.hideBrandChrome {
                VStack(spacing: 8) {
                    Text(L10n.screenOnboardingWelcomeTitle)
                        .font(.compound.headingLGBold)
                        .foregroundColor(.compound.textPrimary)
                        .multilineTextAlignment(.center)
                    Text(L10n.screenOnboardingWelcomeMessage(InfoPlistReader.main.productionAppName))
                        .font(.compound.bodyLG)
                        .foregroundColor(.compound.textPrimary)
                        .multilineTextAlignment(.center)
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
            
            versionText
                .font(.compound.bodySM)
                .foregroundColor(.compound.textSecondary)
                .frame(maxWidth: .infinity)
                .padding(.top, 16)
                .onTapGesture(count: 7) {
                    context.send(viewAction: .reportProblem)
                }
                .accessibilityIdentifier(A11yIdentifiers.authenticationStartScreen.appVersion)
        }
        .padding(.horizontal, verticalSizeClass == .compact ? 128 : 24)
        .readableFrame()
    }
    
    var versionText: Text {
        // Let's not deal with snapshotting a changing version string.
        let shortVersionString = ProcessInfo.isRunningTests ? "0.0.0" : InfoPlistReader.main.bundleShortVersionString
        return Text(L10n.screenOnboardingAppVersion(shortVersionString))
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            if case let .otherOptions(classicAppAccount) = context.viewState.classicAppMode {
                ToolbarButton(role: .close) {
                    context.send(viewAction: .closeOtherOptions(classicAppAccount))
                }
            }
        }
    }
}

// MARK: - Previews

struct AuthenticationStartScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let provisionedViewModel = makeViewModel(provisionedServerName: "example.com")
    static let classicAppViewModel = makeViewModel(hasClassicAppAccount: true)
    
    static var previews: some View {
        AuthenticationStartScreen(context: viewModel.context)
            .previewDisplayName("Default")
        AuthenticationStartScreen(context: provisionedViewModel.context)
            .previewDisplayName("Provisioned")
        
        ElementNavigationStack {
            AuthenticationStartScreen(context: classicAppViewModel.context)
        }
        .previewDisplayName("Classic App")
    }
    
    static func makeViewModel(provisionedServerName: String? = nil, hasClassicAppAccount: Bool = false) -> AuthenticationStartScreenViewModel {
        let classicAppAccount = ClassicAppAccount.mockDan
        classicAppAccount.state.isServerSupported = true
        classicAppAccount.state.availableSecrets = .complete
        let classicAppManager: ClassicAppManagerMock? = hasClassicAppAccount ? .init(.init(accounts: [classicAppAccount])) : nil
        
        return AuthenticationStartScreenViewModel(authenticationService: AuthenticationService.mock(classicAppManager: classicAppManager),
                                                  provisioningParameters: provisionedServerName.map { .init(accountProvider: $0, loginHint: nil) },
                                                  isBugReportServiceEnabled: true,
                                                  appMediator: AppMediatorMock(),
                                                  appSettings: ServiceLocator.shared.settings,
                                                  mediaProvider: MediaProviderMock(configuration: .init()),
                                                  userIndicatorController: UserIndicatorControllerMock())
    }
}
