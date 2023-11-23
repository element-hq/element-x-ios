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

struct PollFormScreen: View {
    @ObservedObject var context: PollFormScreenViewModel.Context
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
            deletePollSection
        }
        .trackAnalyticsIfNeeded(context: context)
        .compoundForm()
        .scrollDismissesKeyboard(.immediately)
        .environment(\.editMode, .constant(.active))
        .navigationTitle(context.viewState.navigationTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .animation(.elementDefault, value: context.options)
        .interactiveDismissDisabled(context.viewState.formContentHasChanged)
        .alert(item: $context.alertInfo)
    }
    
    // MARK: - Private
    
    private var questionSection: some View {
        Section(L10n.screenCreatePollQuestionDesc) {
            TextField(text: $context.question) {
                Text(L10n.screenCreatePollQuestionHint)
                    .compoundFormTextFieldPlaceholder()
            }
            .introspect(.textField, on: .supportedVersions) { textField in
                textField.clearButtonMode = .whileEditing
            }
            .textFieldStyle(.compoundForm)
            .focused($focus, equals: .question)
            .accessibilityIdentifier(A11yIdentifiers.pollFormScreen.question)
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
                    PollFormOptionView(text: $context.options[index].text.limited(to: 240),
                                       placeholder: L10n.screenCreatePollAnswerHint(index + 1),
                                       canDeleteItem: context.options.count > 2) {
                        if case .option(let focusedIndex) = focus, focusedIndex == index {
                            focus = nil
                        }
                        
                        context.send(viewAction: .deleteOption(index: index))
                    }
                    .focused($focus, equals: .option(index: index))
                    .accessibilityIdentifier(A11yIdentifiers.pollFormScreen.optionID(index))
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
                .accessibilityIdentifier(A11yIdentifiers.pollFormScreen.addOption)
            }
        }
        .compoundFormSection()
    }
    
    private var showResultsSection: some View {
        Section {
            Toggle(L10n.screenCreatePollAnonymousDesc, isOn: $context.isUndisclosed)
                .accessibilityIdentifier(A11yIdentifiers.pollFormScreen.pollKind)
        }
        .compoundFormSection()
    }
    
    @ViewBuilder
    private var deletePollSection: some View {
        switch context.viewState.mode {
        case .edit:
            Section {
                Button(role: .destructive) {
                    context.send(viewAction: .delete)
                } label: {
                    Text(L10n.actionDeletePoll)
                }
            }
            .compoundFormSection()
        case .new:
            EmptyView()
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .navigationBarLeading) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(context.viewState.submitButtonTitle) {
                context.send(viewAction: .submit)
            }
            .disabled(context.viewState.isSubmitButtonDisabled)
            .accessibilityIdentifier(A11yIdentifiers.pollFormScreen.submit)
        }
    }
}

private extension View {
    @MainActor @ViewBuilder
    func trackAnalyticsIfNeeded(context: PollFormScreenViewModel.Context) -> some View {
        switch context.viewState.mode {
        case .edit:
            self
        case .new:
            track(screen: .createPoll)
        }
    }
}

private struct PollFormOptionView: View {
    @Environment(\.editMode) var editMode
    @Binding var text: String
    let placeholder: String
    let canDeleteItem: Bool
    let deleteAction: () -> Void
    
    var body: some View {
        HStack(spacing: 8) {
            if editMode?.wrappedValue == .active {
                Button(role: .destructive, action: deleteAction) {
                    CompoundIcon(\.delete)
                }
                .disabled(!canDeleteItem)
                .buttonStyle(.compound(.plain))
                .accessibilityLabel(L10n.actionRemove)
            }
            TextField(text: $text) {
                Text(placeholder)
                    .compoundFormTextFieldPlaceholder()
            }
            .introspect(.textField, on: .supportedVersions) { textField in
                textField.clearButtonMode = .whileEditing
            }
            .textFieldStyle(.compoundForm)
        }
    }
}

// MARK: - Previews

struct PollFormScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = PollFormScreenViewModel(mode: .new)
    static var previews: some View {
        NavigationStack {
            PollFormScreen(context: viewModel.context)
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
