// 
// Copyright 2021 New Vector Ltd
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
import DesignKit

struct LoginScreen: View {
    
    @ObservedObject var context: LoginScreenViewModel.Context
    
    enum Field { case username, password }
    @FocusState private var focussedField: Field?
    
    var body: some View {
        VStack {
            TextField("Username", text: $context.username)
                .textFieldStyle(.elementInput())
                .disableAutocorrection(true)
                .textContentType(.username)
                .autocapitalization(.none)
                .focused($focussedField, equals: .username)
                .submitLabel(.next)
                .onSubmit { focussedField = .password }
            
            SecureField("Password", text: $context.password)
                .textFieldStyle(.elementInput())
                .textContentType(.password)
                .focused($focussedField, equals: .password)
                .submitLabel(.go)
                .onSubmit(submit)
            
            Button("Login", action: submit)
                .buttonStyle(.elementAction(.xLarge))
                .disabled(!context.viewState.hasCredentials)
        }
        .padding(.horizontal, 8.0)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.element.background.ignoresSafeArea())
        .navigationTitle("Login")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    func submit() {
        guard context.viewState.hasCredentials else { return }
        context.send(viewAction: .login)
        focussedField = nil
    }
}

// MARK: - Previews

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = LoginScreenViewModel()
        NavigationView {
            LoginScreen(context: viewModel.context)
        }
        .navigationViewStyle(.stack)
    }
}
