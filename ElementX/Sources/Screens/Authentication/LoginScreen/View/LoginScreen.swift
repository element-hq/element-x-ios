//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct LoginScreen: View {
    /// The focus state of the username text field.
    @FocusState private var isUsernameFocused: Bool
    /// The focus state of the password text field.
    @FocusState private var isPasswordFocused: Bool
    
    @ObservedObject var context: LoginScreenViewModel.Context
    
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
                    loginUnavailableText
                }
            }
            .readableFrame()
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .alert(item: $context.alertInfo)
    }
    
    /// The header containing the title and icon.
    var header: some View {
        VStack(spacing: 8) {
            HeroImage(icon: \.lockSolid)
                .padding(.bottom, 8)
            
            Text(L10n.screenLoginTitleWithHomeserver(context.viewState.homeserver.address))
                .font(.zero.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
        }
        .padding(.horizontal, 16)
    }
    
    /// The form with text fields for username and password, along with a submit button.
    var loginForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.screenLoginFormHeader)
                .font(.zero.bodySM)
                .foregroundColor(.compound.textPrimary)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            TextField(text: $context.username) {
                Text(L10n.commonUsername).foregroundColor(.compound.textPlaceholder)
            }
            .focused($isUsernameFocused)
            .textFieldStyle(.authentication(accessibilityIdentifier: A11yIdentifiers.loginScreen.emailUsername))
            .disableAutocorrection(true)
            .textContentType(.username)
            .autocapitalization(.none)
            .submitLabel(.next)
            .onChange(of: isUsernameFocused, perform: usernameFocusChanged)
            .onSubmit { isPasswordFocused = true }
            .padding(.bottom, 20)
            
            SecureField(text: $context.password) {
                Text(L10n.commonPassword).foregroundColor(.compound.textPlaceholder)
            }
            .focused($isPasswordFocused)
            .textFieldStyle(.authentication(accessibilityIdentifier: A11yIdentifiers.loginScreen.password))
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
    static let credentialsViewModel: LoginScreenViewModel = {
        let viewModel = LoginScreenViewModel(homeserver: .mockMatrixDotOrg, slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL)
        viewModel.context.username = "alice"
        viewModel.context.password = "password"
        return viewModel
    }()
    
    static var previews: some View {
        screen(for: LoginScreenViewModel(homeserver: .mockMatrixDotOrg, slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL))
            .previewDisplayName("matrix.org")
        screen(for: credentialsViewModel)
            .previewDisplayName("Credentials Entered")
        screen(for: LoginScreenViewModel(homeserver: .mockMatrixDotOrg, slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL))
            .previewDisplayName("Unsupported")
        screen(for: LoginScreenViewModel(homeserver: .mockMatrixDotOrg, slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL))
            .previewDisplayName("OIDC Fallback")
    }
    
    static func screen(for viewModel: LoginScreenViewModel) -> some View {
        NavigationStack {
            LoginScreen(context: viewModel.context)
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button { } label: {
                            Text("\(Image(systemName: "chevron.backward")) Back")
                        }
                    }
                }
        }
    }
}
