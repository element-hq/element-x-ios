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

struct SoftLogoutScreen: View {
    // MARK: - Properties
    
    // MARK: Private

    /// The focus state of the password text field.
    @FocusState private var isPasswordFocused: Bool

    // MARK: Public
    
    @ObservedObject var context: SoftLogoutViewModel.Context
    
    // MARK: Views

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, UIConstants.topPaddingToNavigationBar)
                    .padding(.bottom, 36)

                switch context.viewState.loginMode {
                case .password:
                    loginForm
                case .oidc:
                    oidcButton
                default:
                    loginUnavailableText
                }

                clearDataForm
                    .padding(.top, 16)
            }
            .readableFrame()
            .padding(.horizontal, 16)
            .padding(.bottom, 16)
        }
        .background(Color.element.background.ignoresSafeArea())
        .alert(item: $context.alertInfo) { $0.alert }
    }

    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(ElementL10n.authSoftlogoutSignIn)
                .font(.element.title2B)
                .multilineTextAlignment(.leading)
                .foregroundColor(.element.primaryContent)
                .accessibilityIdentifier("titleLabel")

            Text(ElementL10n.authSoftlogoutReason(context.viewState.credentials.homeserverName, context.viewState.credentials.userDisplayName, context.viewState.credentials.userId))
                .font(.element.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(.element.primaryContent)
                .accessibilityIdentifier("messageLabel1")

            if context.viewState.showRecoverEncryptionKeysMessage {
                Text(ElementL10n.authSoftlogoutRecoverEncryptionKeys)
                    .font(.element.body)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.element.primaryContent)
                    .accessibilityIdentifier("messageLabel2")
            }
        }
    }

    /// The form with text fields for username and password, along with a submit button.
    var loginForm: some View {
        VStack(spacing: 14) {
            SecureField(ElementL10n.loginSignupPasswordHint, text: $context.password)
                .focused($isPasswordFocused)
                .textFieldStyle(.elementInput())
                .textContentType(.password)
                .submitLabel(.done)
                .onSubmit(submit)
                .accessibilityIdentifier("passwordTextField")

            Button { context.send(viewAction: .forgotPassword) } label: {
                Text(ElementL10n.authenticationLoginForgotPassword)
                    .font(.element.body)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.bottom, 8)
            .accessibilityIdentifier("forgotPasswordButton")

            Button(action: submit) {
                Text(ElementL10n.loginSignupSubmit)
            }
            .buttonStyle(.elementAction(.xLarge))
            .disabled(!context.viewState.canSubmit)
            .accessibilityIdentifier("nextButton")
        }
    }

    /// The OIDC button that can be used for login.
    var oidcButton: some View {
        Button { context.send(viewAction: .continueWithOIDC) } label: {
            Text(ElementL10n.loginContinue)
        }
        .buttonStyle(.elementAction(.xLarge))
        .accessibilityIdentifier("oidcButton")
    }

    /// Text shown if neither password or OIDC login is supported.
    var loginUnavailableText: some View {
        Text(ElementL10n.autodiscoverWellKnownError)
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.element.primaryContent)
            .frame(maxWidth: .infinity)
            .accessibilityIdentifier("unsupportedServerText")
    }

    /// The text field and submit button where the user enters an email address.
    var clearDataForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(ElementL10n.authSoftlogoutClearData)
                .font(.element.title2B)
                .multilineTextAlignment(.leading)
                .foregroundColor(.element.primaryContent)
                .accessibilityIdentifier("clearDataTitleLabel")

            Text(ElementL10n.authSoftlogoutClearDataMessage1)
                .font(.element.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(.element.primaryContent)
                .accessibilityIdentifier("clearDataMessage1Label")

            Text(ElementL10n.authSoftlogoutClearDataMessage2)
                .font(.element.body)
                .multilineTextAlignment(.leading)
                .foregroundColor(.element.primaryContent)
                .accessibilityIdentifier("clearDataMessage2Label")
                .padding(.bottom, 12)

            Button(action: clearData) {
                Text(ElementL10n.authSoftlogoutClearDataButton)
            }
            .buttonStyle(.elementAction(.xLarge, color: .element.alert))
            .accessibilityIdentifier("clearDataButton")
        }
    }

    /// Sends the `login` view action so long as a valid email address has been input.
    func submit() {
        guard context.viewState.canSubmit else { return }
        context.send(viewAction: .login)
    }

    /// Sends the `forgotPassword` view action.
    func forgotPassword() {
        context.send(viewAction: .forgotPassword)
    }

    /// Sends the `clearAllData` view action.
    func clearData() {
        context.send(viewAction: .clearAllData)
    }
}

// MARK: - Previews

struct SoftLogout_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(MockSoftLogoutScreenState.allCases) { state in
            screen(for: state.viewModel)
        }
    }

    static func screen(for viewModel: SoftLogoutViewModel) -> some View {
        NavigationView {
            SoftLogoutScreen(context: viewModel.context)
                .navigationBarTitleDisplayMode(.inline)
                .tint(.element.accent)
        }
        .navigationViewStyle(.stack)
    }
}
