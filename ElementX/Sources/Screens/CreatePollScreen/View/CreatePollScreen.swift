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

import Compound
import SwiftUI

struct CreatePollScreen: View {
    @ObservedObject var context: CreatePollScreenViewModel.Context
    @FocusState var focus: Focus?

    enum Focus: Hashable {
        case question
        case option(index: Int)
    }

    var body: some View {
        Form {
            questionSection
            optionsSection
            showResultsSection
        }
        .track(screen: .createPoll)
        .compoundForm()
        .scrollDismissesKeyboard(.immediately)
        .environment(\.editMode, .constant(.active))
        .navigationTitle(L10n.screenCreatePollTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .animation(.elementDefault, value: context.options)
        .interactiveDismissDisabled(context.viewState.bindings.hasContent)
        .alert(item: $context.alertInfo)
    }

    // MARK: - Private

    private var questionSection: some View {
        Section(L10n.screenCreatePollQuestionDesc) {
            TextField(text: $context.question) {
                Text(L10n.screenCreatePollQuestionHint)
                    .compoundFormTextFieldPlaceholder()
            }
            .introspect(.textField, on: .iOS(.v16, .v17)) { textField in
                textField.clearButtonMode = .whileEditing
            }
            .textFieldStyle(.compoundForm)
            .focused($focus, equals: .question)
            .accessibilityIdentifier(A11yIdentifiers.createPollScreen.question)
            .onSubmit {
                focus = context.options.indices.first.map { .option(index: $0) }
            }
            .submitLabel(.next)
        }
        .compoundFormSection()
    }

    private var optionsSection: some View {
        Section {
            ForEach(context.options) { option in
                if let index = context.options.firstIndex(of: option) {
                    CreatePollOptionView(text: $context.options[index].text.limited(to: 240),
                                         placeholder: L10n.screenCreatePollAnswerHint(index + 1),
                                         canDeleteItem: context.options.count > 2) {
                        if case .option(let focusedIndex) = focus, focusedIndex == index {
                            focus = nil
                        }

                        context.send(viewAction: .deleteOption(index: index))
                    }
                    .focused($focus, equals: .option(index: index))
                    .accessibilityIdentifier(A11yIdentifiers.createPollScreen.optionID(index))
                    .onSubmit {
                        let nextOptionIndex = index == context.options.endIndex - 1 ? nil : index + 1
                        focus = nextOptionIndex.map { .option(index: $0) }
                    }
                    .submitLabel(index == context.options.endIndex - 1 ? .done : .next)
                }
            }
            .onMove { offsets, toOffset in
                context.options.move(fromOffsets: offsets, toOffset: toOffset)
            }

            if context.options.count < context.viewState.maxNumberOfOptions {
                Button(L10n.screenCreatePollAddOptionBtn) {
                    context.send(viewAction: .addOption)
                    focus = context.options.indices.last.map { .option(index: $0) }
                }
                .accessibilityIdentifier(A11yIdentifiers.createPollScreen.addOption)
            }
        }
        .compoundFormSection()
    }

    private var showResultsSection: some View {
        Section {
            Toggle(L10n.screenCreatePollAnonymousDesc, isOn: $context.isUndisclosed)
                .accessibilityIdentifier(A11yIdentifiers.createPollScreen.pollKind)
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
            .accessibilityIdentifier(A11yIdentifiers.createPollScreen.create)
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
                    CompoundIcon(\.delete)
                        .foregroundColor(.compound.iconCriticalPrimary)
                }
                .disabled(!canDeleteItem)
                .buttonStyle(PlainButtonStyle())
                .accessibilityLabel(L10n.actionRemove)
            }
            TextField(text: $text) {
                Text(placeholder)
                    .compoundFormTextFieldPlaceholder()
            }
            .introspect(.textField, on: .iOS(.v16, .v17)) { textField in
                textField.clearButtonMode = .whileEditing
            }
            .textFieldStyle(.compoundForm)
        }
    }
}

// MARK: - Previews

struct CreatePollScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = CreatePollScreenViewModel()
    static var previews: some View {
        NavigationStack {
            CreatePollScreen(context: viewModel.context)
        }
    }
}

private extension Binding where Value == String {
    func limited(to limit: Int) -> Self {
        .init {
            wrappedValue
        } set: { newValue in
            wrappedValue = String(newValue.prefix(limit))
        }
    }
}
