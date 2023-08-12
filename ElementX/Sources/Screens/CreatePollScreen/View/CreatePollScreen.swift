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
            questionSection
            optionsSection
            showResultsSection
        }
        .compoundForm()
        .scrollDismissesKeyboard(.immediately)
        .environment(\.editMode, .constant(.active))
        .navigationTitle("Create Poll")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
    }

    // MARK: - Private

    private var questionSection: some View {
        Section("Question or topic") {
            TextField(text: $context.question) {
                Text("Question placeholder")
                    .compoundFormTextFieldPlaceholder()
            }
            .introspect(.textField, on: .iOS(.v16)) { textField in
                textField.clearButtonMode = .whileEditing
            }
            .textFieldStyle(.compoundForm)
        }
        .compoundFormSection()
    }

    private var optionsSection: some View {
        Section {
            ForEach(context.options) { option in
                if let index = context.options.firstIndex(of: option) {
                    CreatePollOptionView(text: $context.options[index].text,
                                         placeholder: "Option \(index + 1)",
                                         canDeleteItem: context.options.count > 2) {
                        withAnimation(.elementDefault) {
                            context.send(viewAction: .deleteOption(index: index))
                        }
                    }
                }
            }
            .onMove { offsets, toOffset in
                context.options.move(fromOffsets: offsets, toOffset: toOffset)
            }

            Button("Add option") {
                withAnimation(.elementDefault) {
                    context.send(viewAction: .addOption)
                }
            }
            .disabled(context.options.count >= 20)
        }
        .compoundFormSection()
    }

    private var showResultsSection: some View {
        Section {
            Toggle("Show results only after poll ends", isOn: $context.isUndisclosed)
        }
        .compoundFormSection()
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionCreate) {
                context.send(viewAction: .create)
            }
            .disabled(context.viewState.bindings.isCreateButtonDisabled)
        }
    }
}

private struct CreatePollOptionView: View {
    @Environment(\.editMode) var editMode
    @Binding var text: String
    let placeholder: String
    let canDeleteItem: Bool
    let deleteAction: () -> Void

    var body: some View {
        HStack {
            if editMode?.wrappedValue == .active {
                Button(action: deleteAction) {
                    Image(Asset.Images.delete.name)
                }
                .disabled(!canDeleteItem)
                .buttonStyle(PlainButtonStyle())
            }
            TextField(text: $text) {
                Text(placeholder)
                    .compoundFormTextFieldPlaceholder()
            }
            .introspect(.textField, on: .iOS(.v16)) { textField in
                textField.clearButtonMode = .whileEditing
            }
            .textFieldStyle(.compoundForm)
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
