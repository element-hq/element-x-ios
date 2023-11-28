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
        .compoundList()
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
        Section {
            ListRow(label: .plain(title: L10n.screenCreatePollQuestionHint),
                    kind: .textField(text: $context.question))
                .introspect(.textField, on: .supportedVersions) { textField in
                    textField.clearButtonMode = .whileEditing
                }
                .focused($focus, equals: .question)
                .accessibilityIdentifier(A11yIdentifiers.pollFormScreen.question)
                .onSubmit {
                    focus = context.options.indices.first.map { .option(index: $0) }
                }
                .submitLabel(.next)
        } header: {
            Text(L10n.screenCreatePollQuestionDesc)
                .compoundListSectionHeader()
        }
    }
    
    private var optionsSection: some View {
        Section {
            ForEach(context.options) { option in
                if let index = context.options.firstIndex(of: option) {
                    PollFormOptionRow(text: $context.options[index].text.limited(to: 240),
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
                ListRow(label: .plain(title: L10n.screenCreatePollAddOptionBtn),
                        kind: .button {
                            context.send(viewAction: .addOption)
                            focus = context.options.indices.last.map { .option(index: $0) }
                        })
                        .accessibilityIdentifier(A11yIdentifiers.pollFormScreen.addOption)
            }
        }
    }
    
    private var showResultsSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenCreatePollAnonymousDesc),
                    kind: .toggle($context.isUndisclosed))
                .accessibilityIdentifier(A11yIdentifiers.pollFormScreen.pollKind)
        }
    }
    
    @ViewBuilder
    private var deletePollSection: some View {
        switch context.viewState.mode {
        case .edit:
            Section {
                ListRow(label: .plain(title: L10n.actionDeletePoll, role: .destructive),
                        kind: .button { context.send(viewAction: .delete) })
            }
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

private struct PollFormOptionRow: View {
    @Environment(\.editMode) var editMode
    @Binding var text: String
    let placeholder: String
    let canDeleteItem: Bool
    let deleteAction: () -> Void
    
    var body: some View {
        ListRow(kind: .custom {
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
                        .compoundTextFieldPlaceholder()
                }
                .introspect(.textField, on: .supportedVersions) { textField in
                    textField.clearButtonMode = .whileEditing
                }
                .tint(.compound.iconAccentTertiary)
            }
            .padding(.horizontal, ListRowPadding.horizontal)
            .padding(.vertical, ListRowPadding.vertical)
        })
    }
}

// MARK: - Previews

struct PollFormScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = PollFormScreenViewModel(mode: .new)
    static let editViewModel = PollFormScreenViewModel(mode: .edit(eventID: "1234", poll: poll))
    static let poll = Poll(question: "Cats or Dogs?",
                           kind: .disclosed,
                           maxSelections: 1,
                           options: [
                               .init(id: "0", text: "Cats", votes: 0, allVotes: 0, isSelected: false, isWinning: false),
                               .init(id: "0", text: "Dogs", votes: 0, allVotes: 0, isSelected: false, isWinning: false),
                               .init(id: "0", text: "Fish", votes: 0, allVotes: 0, isSelected: false, isWinning: false)
                           ],
                           votes: [:],
                           endDate: nil,
                           createdByAccountOwner: true)
    
    static var previews: some View {
        NavigationStack {
            PollFormScreen(context: viewModel.context)
        }
        .previewDisplayName("New")
        
        NavigationStack {
            PollFormScreen(context: editViewModel.context)
        }
        .previewDisplayName("Edit")
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
