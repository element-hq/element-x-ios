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

struct LoginScreen: View {
    /// The focus state of the username text field.
    @FocusState private var isUsernameFocused: Bool
    /// The focus state of the password text field.
    @FocusState private var isPasswordFocused: Bool
    
    @ObservedObject var context: LoginViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, UIConstants.titleTopPaddingToNavigationBar)
                    .padding(.bottom, 32)
                
                serverInfo
                    .padding(.bottom, 32)
                
                switch context.viewState.loginMode {
                case .password:
                    loginForm
                case .oidc:
                    oidcButton
                default:
                    loginUnavailableText
                }
            }
            .readableFrame()
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.element.background.ignoresSafeArea())
        .alert(item: $context.alertInfo) { $0.alert }
    }
    
    /// The header containing a Welcome Back title.
    var header: some View {
        Text(L10n.loginTitle)
            .font(.element.title1Bold)
            .multilineTextAlignment(.center)
            .foregroundColor(.element.primaryContent)
    }
    
    /// The sever information section that includes a button to select a different server.
    var serverInfo: some View {
        LoginServerInfoSection(address: context.viewState.homeserver.address) {
            context.send(viewAction: .selectServer)
        }
    }
    
    /// The form with text fields for username and password, along with a submit button.
    var loginForm: some View {
        VStack(alignment: .leading, spacing: 0) {
            Text(L10n.commonEnterYourDetails)
                .font(.element.footnote)
                .foregroundColor(.element.primaryContent)
                .padding(.horizontal, 16)
                .padding(.bottom, 8)
            
            TextField(L10n.commonUsername,
                      text: $context.username,
                      // Prompt colour fixes a flicker that occurs before the text field style introspects the field.
                      prompt: Text(L10n.commonUsername).foregroundColor(.element.tertiaryContent))
                .focused($isUsernameFocused)
                .textFieldStyle(.elementInput(accessibilityIdentifier: A11yIdentifiers.loginScreen.emailUsername))
                .disableAutocorrection(true)
                .textContentType(.username)
                .autocapitalization(.none)
                .submitLabel(.next)
                .onChange(of: isUsernameFocused, perform: usernameFocusChanged)
                .onSubmit { isPasswordFocused = true }
                .padding(.bottom, 20)
            
            SecureField(L10n.commonPassword,
                        text: $context.password,
                        // Prompt colour fixes a flicker that occurs before the text field style introspects the field.
                        prompt: Text(L10n.commonPassword).foregroundColor(.element.tertiaryContent))
                .focused($isPasswordFocused)
                .textFieldStyle(.elementInput(accessibilityIdentifier: A11yIdentifiers.loginScreen.password))
                .textContentType(.password)
                .submitLabel(.done)
                .onSubmit(submit)
            
            Spacer().frame(height: 32)

            Button(action: submit) {
                Text(L10n.actionContinue)
            }
            .buttonStyle(.elementAction(.xLarge))
            .disabled(!context.viewState.canSubmit)
            .accessibilityIdentifier(A11yIdentifiers.loginScreen.continue)
        }
    }

    /// The OIDC button that can be used for login.
    var oidcButton: some View {
        Button { context.send(viewAction: .continueWithOIDC) } label: {
            Text(L10n.actionContinue)
        }
        .buttonStyle(.elementAction(.xLarge))
        .accessibilityIdentifier(A11yIdentifiers.loginScreen.oidc)
    }
    
    /// Text shown if neither password or OIDC login is supported.
    var loginUnavailableText: some View {
        Text(L10n.loginErrorUnsupportedAuthentication)
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.element.primaryContent)
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

struct Login_Previews: PreviewProvider {
    static let credentialsViewModel: LoginViewModel = {
        let viewModel = LoginViewModel(homeserver: .mockMatrixDotOrg)
        viewModel.context.username = "alice"
        viewModel.context.password = "password"
        return viewModel
    }()
    
    static var previews: some View {
        screen(for: LoginViewModel(homeserver: .mockMatrixDotOrg))
            .previewDisplayName("matrix.org")
        screen(for: credentialsViewModel)
            .previewDisplayName("Credentials Entered")
        screen(for: LoginViewModel(homeserver: .mockOIDC))
            .previewDisplayName("OIDC")
        screen(for: LoginViewModel(homeserver: .mockUnsupported))
            .previewDisplayName("Unsupported")
    }
    
    static func screen(for viewModel: LoginViewModel) -> some View {
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
