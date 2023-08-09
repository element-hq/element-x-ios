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

struct CreatePollScreen: View {
    @ObservedObject var context: CreatePollScreenViewModel.Context
    
    var body: some View {
        Form {
            Section {
                TextField(text: $context.composerText) {
                    Text(context.viewState.placeholder)
                        .compoundFormTextFieldPlaceholder()
                }
                .textFieldStyle(.compoundForm)
                
                Button {
                    context.send(viewAction: .done)
                } label: {
                    Label("Done", systemImage: "door.left.hand.closed")
                }
                .buttonStyle(.compoundFormCentred())
            }
            .compoundFormSection()
        }
        .compoundForm()
        .navigationTitle(context.viewState.title)
        .onChange(of: context.composerText) { _ in
            context.send(viewAction: .textChanged)
        }
    }
}

// MARK: - Previews

struct CreatePollScreen_Previews: PreviewProvider {
    static let viewModel = CreatePollScreenViewModel()
    static var previews: some View {
        NavigationStack {
            CreatePollScreen(context: viewModel.context)
        }
    }
}
