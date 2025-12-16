//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct LoginScreen: View {
    /// The focus state of the username text field.
    @FocusState private var isUsernameFocused: Bool
    /// The focus state of the password text field.
    @FocusState private var isPasswordFocused: Bool
    
    @Bindable var context: LoginScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, UIConstants.titleTopPaddingToNavigationBar)
                    .padding(.bottom, 32)
                
                switch context.viewState.loginMode {
                case .password:
                    loginForm
                case .oidc:
                    // This should never be shown.
                    ProgressView()
                default:
                    // This should never be shown either.
                    loginUnavailableText
                }
            }
            .readableFrame()
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
    }
    
    /// The header containing the title and icon.
    var header: some View {
        VStack(spacing: 8) {
            BigIcon(icon: \.lockSolid)
                .padding(.bottom, 8)
            
            Text(L10n.screenLoginTitleWithHomeserver(context.viewState.homeserver.address))
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
        }
        .padding(.horizontal, 16)
    }
    
    /// The form with text fields for username and password, along with a submit button.
    var loginForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.screenLoginFormHeader)
                .font(.compound.bodySM)
                .foregroundColor(.compound.textPrimary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            TextField(text: $context.username) {
                Text(L10n.commonUsername).foregroundColor(.compound.textSecondary)
            }
            .focused($isUsernameFocused)
            .textFieldStyle(.element(accessibilityIdentifier: A11yIdentifiers.loginScreen.emailUsername))
            .disableAutocorrection(true)
            .textContentType(.username)
            .autocapitalization(.none)
            .submitLabel(.next)
            .onChange(of: isUsernameFocused) { _, newValue in
                usernameFocusChanged(isFocussed: newValue)
            }
            .onSubmit { isPasswordFocused = true }
            .padding(.bottom, 20)
            
            SecureField(text: $context.password) {
                Text(L10n.commonPassword).foregroundColor(.compound.textSecondary)
            }
            .focused($isPasswordFocused)
            .textFieldStyle(.element(accessibilityIdentifier: A11yIdentifiers.loginScreen.password))
            .textContentType(.password)
            .submitLabel(.done)
            .onSubmit(submit)
            
            Spacer().frame(height: 32)

            Button(action: submit) {
                Text(L10n.actionContinue)
            }
            .buttonStyle(.compound(.primary))
            .disabled(!context.viewState.canSubmit)
            .accessibilityIdentifier(A11yIdentifiers.loginScreen.continue)
        }
    }
    
    /// Text shown if neither password or OIDC login is supported.
    var loginUnavailableText: some View {
        Text(L10n.screenLoginErrorUnsupportedAuthentication)
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.compound.textPrimary)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier(A11yIdentifiers.loginScreen.unsupportedServer)
    }
    
    /// Parses the username for a homeserver.
    private func usernameFocusChanged(isFocussed: Bool) {
        guard !isFocussed, !context.username.isEmpty else { return }
        context.send(viewAction: .parseUsername)
    }
    
    /// Sends the `next` view action so long as valid credentials have been input.
    private func submit() {
        guard context.viewState.canSubmit else { return }
        context.send(viewAction: .next)
        isUsernameFocused = false
        isPasswordFocused = false
    }
}

// MARK: - Previews

struct LoginScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let credentialsViewModel = makeViewModel(withCredentials: true)
    static let unconfiguredViewModel = makeViewModel(homeserverAddress: "somethingtofailconfiguration")
    
    static var previews: some View {
        NavigationStack {
            LoginScreen(context: viewModel.context)
        }
        .snapshotPreferences(expect: viewModel.context.observe(\.viewState.homeserver.loginMode).map { $0 == .password })
        .previewDisplayName("Initial State")
        
        NavigationStack {
            LoginScreen(context: credentialsViewModel.context)
        }
        .snapshotPreferences(expect: credentialsViewModel.context.observe(\.viewState.homeserver.loginMode).map { $0 == .password })
        .previewDisplayName("Credentials Entered")
        
        NavigationStack {
            LoginScreen(context: unconfiguredViewModel.context)
        }
        .previewDisplayName("Unsupported")
    }
    
    static func makeViewModel(homeserverAddress: String = "example.com", withCredentials: Bool = false) -> LoginScreenViewModel {
        let authenticationService = AuthenticationService.mock
        
        Task { await authenticationService.configure(for: homeserverAddress, flow: .login) }
        
        let viewModel = LoginScreenViewModel(authenticationService: authenticationService,
                                             loginHint: nil,
                                             userIndicatorController: UserIndicatorControllerMock(),
                                             appSettings: ServiceLocator.shared.settings,
                                             analytics: ServiceLocator.shared.analytics)
        
        if withCredentials {
            viewModel.context.username = "alice"
            viewModel.context.password = "password"
        }
        
        return viewModel
    }
}
