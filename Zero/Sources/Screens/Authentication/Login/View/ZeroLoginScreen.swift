//
// Copyright 2024 New Vector Ltd
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

struct ZeroLoginScreen: View {
    /// The focus state of the username text field.
    @FocusState private var isUsernameFocused: Bool
    /// The focus state of the password text field.
    @FocusState private var isPasswordFocused: Bool
    
    @State private var selectedSegment: LoginMethod = .email
    
    @ObservedObject var context: LoginScreenViewModel.Context
    
    var body: some View {
        VStack {
            loginSegmentControl
            
            switch selectedSegment {
            case .web3:
                web3LoginView
            case .email:
                loginForm
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .modifier(ZeroAuthBackgroundModifier())
        .navigationTitle("Log In")
        .navigationBarTitleDisplayMode(.inline)
        .alert(item: $context.alertInfo)
    }
    
    var web3LoginView: some View {
        Button { } label: {
            Image(asset: Asset.Images.defaultWalletConnectButton)
        }
        .padding(.top, 40)
    }
    
    var loginSegmentControl: some View {
        Picker("Login Method", selection: $selectedSegment) {
            ForEach(LoginMethod.allCases, id: \.self) { option in
                Text(option.rawValue)
            }
        }.pickerStyle(.segmented)
            .padding(.horizontal, 36)
            .padding(.top, 60)
    }
    
    var loginForm: some View {
        VStack(alignment: .center, spacing: 0) {
            TextField(text: $context.username) {
                Text("Email").foregroundColor(.compound.textPlaceholder)
            }
            .focused($isUsernameFocused)
            .textFieldStyle(.authentication(accessibilityIdentifier: A11yIdentifiers.loginScreen.emailUsername))
            .disableAutocorrection(true)
            .textContentType(.emailAddress)
            .keyboardType(.emailAddress)
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
            
            Spacer().frame(height: 36)

            Button(action: submit) {
                Image(asset: Asset.Images.defaultLoginButton)
            }
            .frame(width: 167, height: 48)
            .disabled(!context.viewState.canSubmit)
            .accessibilityIdentifier(A11yIdentifiers.loginScreen.continue)
        }
        .padding(.horizontal, 36)
        .padding(.top, 36)
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

public enum LoginMethod: String, Equatable, CaseIterable {
    case web3 = "Web3"
    case email = "Email"
}

// MARK: - Previews

struct ZeroLoginScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = makeViewModel()
    static let credentialsViewModel = makeViewModel(withCredentials: true)
    static let unconfiguredViewModel = makeViewModel(homeserverAddress: "somethingtofailconfiguration")
    
    static var previews: some View {
        NavigationStack {
            ZeroLoginScreen(context: viewModel.context)
        }
        .previewDisplayName("matrix.org")
        .snapshotPreferences(delay: 0.1)
        
        NavigationStack {
            ZeroLoginScreen(context: credentialsViewModel.context)
        }
        .previewDisplayName("Credentials Entered")
        .snapshotPreferences(delay: 0.1)
        
        NavigationStack {
            ZeroLoginScreen(context: unconfiguredViewModel.context)
        }
        .previewDisplayName("Unsupported")
        .snapshotPreferences(delay: 0.1)
    }
    
    static func makeViewModel(homeserverAddress: String = "matrix.org", withCredentials: Bool = false) -> LoginScreenViewModel {
        let authenticationService = AuthenticationService.mock
        
        Task { await authenticationService.configure(for: homeserverAddress, flow: .login) }
        
        let viewModel = LoginScreenViewModel(authenticationService: authenticationService,
                                             slidingSyncLearnMoreURL: ServiceLocator.shared.settings.slidingSyncLearnMoreURL,
                                             userIndicatorController: UserIndicatorControllerMock(),
                                             analytics: ServiceLocator.shared.analytics)
        
        if withCredentials {
            viewModel.context.username = "alice"
            viewModel.context.password = "password"
        }
        
        return viewModel
    }
}
