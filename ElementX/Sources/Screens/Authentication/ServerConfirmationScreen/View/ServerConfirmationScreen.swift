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

struct ServerConfirmationScreen: View {
    @ObservedObject var context: ServerConfirmationScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            header
                .padding(.top, UIConstants.iconTopPaddingToNavigationBar)
                .padding(.horizontal, 16)
                .readableFrame()
        }
        .background(Color.element.background.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) {
            buttons
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
                .readableFrame()
                .background(Color.element.background.ignoresSafeArea())
        }
    }
    
    /// The main content of the view to be shown in a scroll view.
    var header: some View {
        VStack(spacing: 8) {
            AuthenticationIconImage(image: Image(systemName: "person.crop.circle.fill"))
                .padding(.bottom, 8)
            
            Text(context.viewState.title)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.element.primaryContent)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(context.viewState.message)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.element.tertiaryContent)
        }
        .padding(.horizontal, 16)
    }
    
    /// The action buttons shown at the bottom of the view.
    var buttons: some View {
        VStack(spacing: 24) {
            Button { context.send(viewAction: .confirm) } label: {
                Text(L10n.actionContinue)
            }
            .buttonStyle(.elementAction(.xLarge))
            .accessibilityIdentifier(A11yIdentifiers.serverConfirmationScreen.continue)
            
            Button { context.send(viewAction: .changeServer) } label: {
                Text(L10n.screenServerConfirmationChangeServer)
                    .font(.compound.bodyLGSemibold)
                    .padding(.vertical, 14)
            }
            .accessibilityIdentifier(A11yIdentifiers.serverConfirmationScreen.changeServer)
        }
    }
}

// MARK: - Previews

struct ServerConfirmationScreen_Previews: PreviewProvider {
    static let loginViewModel = ServerConfirmationScreenViewModel(authenticationService: MockAuthenticationServiceProxy(),
                                                                  authenticationFlow: .login)
    static let registerViewModel = ServerConfirmationScreenViewModel(authenticationService: MockAuthenticationServiceProxy(),
                                                                     authenticationFlow: .register)
    
    static var previews: some View {
        NavigationStack {
            ServerConfirmationScreen(context: loginViewModel.context)
                .toolbar(.visible, for: .navigationBar)
        }
        .previewDisplayName("Login")
        
        NavigationStack {
            ServerConfirmationScreen(context: registerViewModel.context)
                .toolbar(.visible, for: .navigationBar)
        }
        .previewDisplayName("Register")
    }
}
