//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct CreateAccountScreen: View {
    @ObservedObject var context: CreateAccountScreenViewModel.Context
    
    @State private var selectedSegment: ZeroAuthenticationMethod = .email
    
    @FocusState private var isEmailFocused: Bool
    @FocusState private var isPasswordFocused: Bool
    @FocusState private var isConfirmPasswordFocused: Bool
    
    var body: some View {
        VStack {
            ScrollView {
                VStack {
                    createAccountSegmentControl
                    
                    switch selectedSegment {
                    case .web3:
                        web3CreateAccountView
                    case .email:
                        createAccountForm
                    }
                    
                    Spacer()
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(ZeroAuthBackgroundModifier())
        .navigationTitle("Create Account")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
    }
    
    var createAccountSegmentControl: some View {
        Picker("Create Account Method", selection: $selectedSegment) {
            ForEach(ZeroAuthenticationMethod.allCases, id: \.self) { option in
                Text(option.rawValue)
            }
        }.pickerStyle(.segmented)
            .padding(.horizontal, 36)
            .padding(.top, 60)
    }
    
    var web3CreateAccountView: some View {
        Button {
            context.send(viewAction: .openWalletConnectModal)
        } label: {
            Image(asset: Asset.Images.defaultWalletConnectButton)
        }
        .padding(.top, 40)
    }
    
    var createAccountForm: some View {
        VStack(alignment: .center, spacing: 0) {
            TextField(text: $context.emailAddress) {
                Text("Email Address").foregroundColor(.compound.textSecondary)
            }
            .focused($isEmailFocused)
            .textFieldStyle(.element(accessibilityIdentifier: "create-account_email_address"))
            .disableAutocorrection(true)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
            .autocapitalization(.none)
            .submitLabel(.next)
            .onSubmit { isPasswordFocused = true }
            
            if !context.emailAddress.isEmpty, !context.viewState.isEmailValid {
                InfoBox(text: "Please enter a valid email address", type: .error)
            }
            
            Spacer().frame(height: 20)
            
            SecureInputField(text: $context.password,
                             isFocused: $isPasswordFocused,
                             placeHolder: L10n.commonPassword,
                             accessibilityIdentifier: "create-account_password",
                             submitLabel: .next,
                             onSubmit: {
                                 isConfirmPasswordFocused = true
                             })
            
            if !context.password.isEmpty {
                let infoBoxType: InfoBoxType = context.viewState.isValidPassword ? .success : (isPasswordFocused ? .general : .error)
                InfoBox(text: "Must include at least 8 characters, 1 number, 1 lowercase and 1 uppercase letter",
                        type: infoBoxType)
            }
            
            Spacer().frame(height: 20)
            
            SecureInputField(text: $context.confirmPassword,
                             isFocused: $isConfirmPasswordFocused,
                             placeHolder: "Confirm Password",
                             accessibilityIdentifier: "create-account_confirm_password",
                             submitLabel: .done,
                             onSubmit: submit)
            
            if !context.confirmPassword.isEmpty {
                let infoBoxText = context.viewState.isValidConfirmPassword ? "Passwords match" : "Passwords do not match"
                let infoBoxType: InfoBoxType = context.viewState.isValidConfirmPassword ? .success : .error
                
                InfoBox(text: infoBoxText, type: infoBoxType)
            }
            
            Spacer().frame(height: 40)
            
            ZeroStyledButton(buttonText: "Create account",
                             buttonImageAsset: Asset.Images.btnCreateAccount,
                             action: submit,
                             enabled: context.viewState.canSubmit)
            
            VStack {
                Text("Already on ZERO? ")
                    .font(.zero.bodyMD)
                    .foregroundColor(.compound.textSecondary)
                    + Text("Log In")
                    .font(.zero.bodyMD)
                    .foregroundColor(Color.zero.bgAccentRest)
                    .underline()
            }
            .padding(.top, 56)
            .onTapGesture { context.send(viewAction: .openLoginScreen) }
        }
        .padding(.horizontal, 36)
        .padding(.top, 36)
    }
    
    private func submit() {
        guard context.viewState.canSubmit else { return }
        context.send(viewAction: .createAccount)
        isEmailFocused = false
        isPasswordFocused = false
        isConfirmPasswordFocused = false
    }
}
