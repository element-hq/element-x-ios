//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct SoftLogoutScreen: View {
    @State private var showingClearDataConfirmation = false

    /// The focus state of the password text field.
    @FocusState private var isPasswordFocused: Bool

    @ObservedObject var context: SoftLogoutScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, UIConstants.titleTopPaddingToNavigationBar)
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
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .alert(item: $context.alertInfo)
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
    }

    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(UntranslatedL10n.softLogoutSigninTitle)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.leading)
                .foregroundColor(.compound.textPrimary)
                .accessibilityIdentifier(A11yIdentifiers.softLogoutScreen.title)

            Text(UntranslatedL10n.softLogoutSigninNotice(context.viewState.credentials.homeserverName, context.viewState.credentials.userDisplayName, context.viewState.credentials.userID))
                .font(.compound.bodyLG)
                .multilineTextAlignment(.leading)
                .foregroundColor(.compound.textPrimary)
                .accessibilityIdentifier(A11yIdentifiers.softLogoutScreen.message)

            if context.viewState.showRecoverEncryptionKeysMessage {
                Text(UntranslatedL10n.softLogoutSigninE2eWarningNotice)
                    .font(.compound.bodyLG)
                    .multilineTextAlignment(.leading)
                    .foregroundColor(.compound.textPrimary)
            }
        }
    }

    /// The form with text fields for username and password, along with a submit button.
    var loginForm: some View {
        VStack(spacing: 14) {
            SecureField(L10n.commonPassword, text: $context.password)
                .focused($isPasswordFocused)
                .textFieldStyle(.authentication())
                .textContentType(.password)
                .submitLabel(.done)
                .onSubmit(submit)
                .accessibilityIdentifier(A11yIdentifiers.softLogoutScreen.password)

            Button { context.send(viewAction: .forgotPassword) } label: {
                Text(L10n.actionForgotPassword)
                    .font(.compound.bodyLG)
            }
            .frame(maxWidth: .infinity, alignment: .trailing)
            .padding(.bottom, 8)
            .accessibilityIdentifier(A11yIdentifiers.softLogoutScreen.forgotPassword)

            Button(action: submit) {
                Text(L10n.actionNext)
            }
            .buttonStyle(.compound(.primary))
            .disabled(!context.viewState.canSubmit)
            .accessibilityIdentifier(A11yIdentifiers.softLogoutScreen.next)
        }
    }

    /// The OIDC button that can be used for login.
    var oidcButton: some View {
        Button { context.send(viewAction: .continueWithOIDC) } label: {
            Text(L10n.actionContinue)
        }
        .buttonStyle(.compound(.primary))
    }

    /// Text shown if neither password or OIDC login is supported.
    var loginUnavailableText: some View {
        Text(L10n.screenLoginErrorUnsupportedAuthentication)
            .font(.body)
            .multilineTextAlignment(.center)
            .foregroundColor(.compound.textPrimary)
            .frame(maxWidth: .infinity)
    }

    /// The text field and submit button where the user enters an email address.
    var clearDataForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(UntranslatedL10n.softLogoutClearDataTitle)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.leading)
                .foregroundColor(.compound.textPrimary)
                .accessibilityIdentifier(A11yIdentifiers.softLogoutScreen.clearDataTitle)

            Text(UntranslatedL10n.softLogoutClearDataNotice)
                .font(.compound.bodyLG)
                .multilineTextAlignment(.leading)
                .foregroundColor(.compound.textPrimary)
                .accessibilityIdentifier(A11yIdentifiers.softLogoutScreen.clearDataMessage)
                .padding(.bottom, 12)

            Button(role: .destructive, action: clearData) {
                Text(UntranslatedL10n.softLogoutClearDataSubmit)
            }
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.softLogoutScreen.clearData)
            .alert(UntranslatedL10n.softLogoutClearDataDialogTitle,
                   isPresented: $showingClearDataConfirmation) {
                Button(L10n.screenSignoutConfirmationDialogSubmit,
                       role: .destructive,
                       action: clearData)
            } message: {
                Text(UntranslatedL10n.softLogoutClearDataDialogContent)
            }
        }
    }

    /// Sends the `login` view action so long as a valid email address has been input.
    func submit() {
        guard context.viewState.canSubmit else { return }
        context.send(viewAction: .login)
    }

    /// Sends the `clearAllData` view action.
    func clearData() {
        context.send(viewAction: .clearAllData)
    }
}

// MARK: - Previews

struct SoftLogoutScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        ForEach(MockSoftLogoutScreenState.allCases) { state in
            screen(for: state.viewModel)
        }
    }

    static func screen(for viewModel: SoftLogoutScreenViewModel) -> some View {
        NavigationStack {
            SoftLogoutScreen(context: viewModel.context)
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
