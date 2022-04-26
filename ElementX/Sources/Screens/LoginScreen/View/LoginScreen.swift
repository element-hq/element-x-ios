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

struct LoginScreen: View {
    
    @ObservedObject var context: LoginScreenViewModel.Context
    
    var body: some View {
        NavigationView {
            VStack {
                TextField("Username", text: $context.username)
                    .textFieldStyle(.roundedBorder)
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                SecureField("Password", text: $context.password)
                    .textFieldStyle(.roundedBorder)
                
                Button("Login") {
                    context.send(viewAction: .login)
                }
                .buttonStyle(.borderedProminent)
                .padding(.horizontal, 50)
            }
            .padding(.horizontal, 8.0)
            .navigationTitle("Login")
            .navigationBarTitleDisplayMode(.inline)
            .onSubmit {
                context.send(viewAction: .login)
            }
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }
}

// MARK: - Previews

struct LoginScreen_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = LoginScreenViewModel()
        LoginScreen(context: viewModel.context)
    }
}
