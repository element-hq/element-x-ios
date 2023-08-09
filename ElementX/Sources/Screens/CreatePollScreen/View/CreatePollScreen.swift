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
    @State var text = ""
    
    var body: some View {
        Form {
            Section("Question or topic") {
                ForEach(context.options, id: \.self) { _ in
                    TextField(text: $text) {
                        Text("Placeholder")
                            .compoundFormTextFieldPlaceholder()
                    }
                    .textFieldStyle(.compoundForm)
                }
            }
            .compoundFormSection()
        }
        .compoundForm()
        .navigationTitle("Nav title")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
    }

    // MARK: - Private

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }

        ToolbarItem(placement: .navigationBarTrailing) {
            Button(L10n.actionCreate) {
                context.send(viewAction: .create)
            }
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
