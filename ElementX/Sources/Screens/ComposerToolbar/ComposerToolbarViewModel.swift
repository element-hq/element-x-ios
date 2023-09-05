//
// Copyright 2023 New Vector Ltd
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

import Combine
import Foundation
import SwiftUI
import WysiwygComposer

typealias ComposerToolbarViewModelType = StateStoreViewModel<ComposerToolbarViewState, ComposerToolbarViewAction>

final class ComposerToolbarViewModel: ComposerToolbarViewModelType, ComposerToolbarViewModelProtocol {
    private let wysiwygViewModel: WysiwygComposerViewModel
    private let actionsSubject: PassthroughSubject<ComposerToolbarViewModelAction, Never> = .init()
    var actions: AnyPublisher<ComposerToolbarViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    private struct WysiwygLinkData {
        let action: LinkAction
        let range: NSRange
        var url: String
        var text: String
    }

    private var currentLinkData: WysiwygLinkData?

    init(wysiwygViewModel: WysiwygComposerViewModel) {
        self.wysiwygViewModel = wysiwygViewModel

        super.init(initialViewState: ComposerToolbarViewState(bindings: .init()))

        context.$viewState
            .map(\.composerMode)
            .removeDuplicates()
            .sink { [weak self] in self?.actionsSubject.send(.composerModeChanged(mode: $0)) }
            .store(in: &cancellables)

        context.$viewState
            .map(\.bindings.composerFocused)
            .removeDuplicates()
            .sink { [weak self] in self?.actionsSubject.send(.composerFocusedChanged(isFocused: $0)) }
            .store(in: &cancellables)

        wysiwygViewModel.$isContentEmpty
            .weakAssign(to: \.state.composerEmpty, on: self)
            .store(in: &cancellables)

        wysiwygViewModel.$actionStates
            .map { actions in
                FormatType
                    .allCases
                    // Exclude indent type outside of lists.
                    .filter { wysiwygViewModel.isInList || !$0.isIndentType }
                    .map { type in
                        FormatItem(type: type,
                                   state: actions[type.composerAction] ?? .disabled)
                    }
            }
            .weakAssign(to: \.state.bindings.formatItems, on: self)
            .store(in: &cancellables)
    }

    // MARK: - Public

    override func process(viewAction: ComposerToolbarViewAction) {
        switch viewAction {
        case .composerAppeared:
            wysiwygViewModel.setup()
        case .sendMessage:
            guard !state.sendButtonDisabled else { return }

            if ServiceLocator.shared.settings.richTextEditorEnabled {
                actionsSubject.send(.sendMessage(plain: wysiwygViewModel.content.markdown,
                                                 html: wysiwygViewModel.content.html,
                                                 mode: state.composerMode))
            } else {
                actionsSubject.send(.sendPlainTextMessage(message: context.composerPlainText,
                                                          mode: state.composerMode))
            }
            state.bindings.composerActionsEnabled = false
        case .cancelReply:
            set(mode: .default)
        case .cancelEdit:
            set(mode: .default)
            set(text: "")
        case .displayCameraPicker:
            actionsSubject.send(.displayCameraPicker)
        case .displayMediaPicker:
            actionsSubject.send(.displayMediaPicker)
        case .displayDocumentPicker:
            actionsSubject.send(.displayDocumentPicker)
        case .displayLocationPicker:
            actionsSubject.send(.displayLocationPicker)
        case .displayPollForm:
            actionsSubject.send(.displayPollForm)
        case .handlePasteOrDrop(let provider):
            actionsSubject.send(.handlePasteOrDrop(provider: provider))
        case .enableTextFormatting:
            state.bindings.composerActionsEnabled = true
            state.bindings.composerFocused = true
        case .composerAction(let action):
            if action == .link {
                createLinkAlert()
            } else {
                wysiwygViewModel.apply(action)
            }
        }
    }

    func process(roomAction: RoomScreenComposerAction) {
        switch roomAction {
        case .setMode(mode: let mode):
            set(mode: mode)
        case .setText(text: let text):
            set(text: text)
        case .removeFocus:
            state.bindings.composerFocused = false
        case .clear:
            set(mode: .default)
            set(text: "")
        }
    }

    func handleKeyCommand(_ keyCommand: WysiwygKeyCommand) -> Bool {
        switch keyCommand {
        case .enter:
            process(viewAction: .sendMessage)
            return true
        case .shiftEnter:
            return false
        }
    }

    // MARK: - Private

    private func set(mode: RoomScreenComposerMode) {
        guard mode != state.composerMode else { return }

        state.composerMode = mode
        if mode != .default {
            // Focus composer when switching to reply/edit
            state.bindings.composerFocused = true
        }
    }

    private func set(text: String) {
        if ServiceLocator.shared.settings.richTextEditorEnabled {
            wysiwygViewModel.setMarkdownContent(text)
        } else {
            state.bindings.composerPlainText = text
        }
    }

    private func createLinkAlert() {
        let linkAction = wysiwygViewModel.getLinkAction()
        currentLinkData = WysiwygLinkData(action: linkAction,
                                          range: wysiwygViewModel.attributedContent.selection,
                                          url: linkAction.url ?? "",
                                          text: "")

        let urlBinding: Binding<String> = .init { [weak self] in
            self?.currentLinkData?.url ?? ""
        } set: { [weak self] value in
            self?.currentLinkData?.url = value
        }

        let textBinding: Binding<String> = .init { [weak self] in
            self?.currentLinkData?.text ?? ""
        } set: { [weak self] value in
            self?.currentLinkData?.text = value
        }

        switch linkAction {
        case .createWithText:
            state.bindings.alertInfo = makeCreateWithTextAlertInfo(urlBinding: urlBinding, textBinding: textBinding)
        case .create:
            state.bindings.alertInfo = makeSetUrlAlertInfo(urlBinding: urlBinding, isEdit: false)
        case .edit:
            state.bindings.alertInfo = makeEditChoiceAlertInfo(urlBinding: urlBinding)
        case .disabled:
            break
        }
    }

    private func makeCreateWithTextAlertInfo(urlBinding: Binding<String>, textBinding: Binding<String>) -> AlertInfo<UUID> {
        AlertInfo(id: UUID(),
                  title: L10n.richTextEditorCreateLink,
                  primaryButton: AlertInfo<UUID>.AlertButton(title: L10n.actionCancel, action: {
                      self.restoreComposerSelectedRange()
                  }),
                  secondaryButton: AlertInfo<UUID>.AlertButton(title: L10n.actionSave, action: {
                      self.restoreComposerSelectedRange()
                      self.createLinkWithText()

                  }),
                  textFields: [AlertInfo<UUID>.AlertTextField(placeholder: L10n.commonText,
                                                              text: textBinding,
                                                              autoCapitalization: .never,
                                                              autoCorrectionDisabled: false),
                               AlertInfo<UUID>.AlertTextField(placeholder: L10n.richTextEditorUrlPlaceholder,
                                                              text: urlBinding,
                                                              autoCapitalization: .never,
                                                              autoCorrectionDisabled: true)])
    }

    private func makeSetUrlAlertInfo(urlBinding: Binding<String>, isEdit: Bool) -> AlertInfo<UUID> {
        AlertInfo(id: UUID(),
                  title: isEdit ? L10n.richTextEditorEditLink : L10n.richTextEditorCreateLink,
                  primaryButton: AlertInfo<UUID>.AlertButton(title: L10n.actionCancel, action: {
                      self.restoreComposerSelectedRange()
                  }),
                  secondaryButton: AlertInfo<UUID>.AlertButton(title: L10n.actionSave, action: {
                      self.restoreComposerSelectedRange()
                      self.setLink()

                  }),
                  textFields: [AlertInfo<UUID>.AlertTextField(placeholder: L10n.richTextEditorUrlPlaceholder,
                                                              text: urlBinding,
                                                              autoCapitalization: .never,
                                                              autoCorrectionDisabled: true)])
    }

    private func makeEditChoiceAlertInfo(urlBinding: Binding<String>) -> AlertInfo<UUID> {
        AlertInfo(id: UUID(),
                  title: L10n.richTextEditorEditLink,
                  primaryButton: AlertInfo<UUID>.AlertButton(title: L10n.actionRemove, role: .destructive, action: {
                      self.restoreComposerSelectedRange()
                      self.removeLinks()
                  }),
                  verticalButtons: [AlertInfo<UUID>.AlertButton(title: L10n.actionEdit, action: {
                      self.state.bindings.alertInfo = nil
                      DispatchQueue.main.async {
                          self.state.bindings.alertInfo = self.makeSetUrlAlertInfo(urlBinding: urlBinding, isEdit: true)
                      }
                  })])
    }

    private func restoreComposerSelectedRange() {
        guard let currentLinkData else { return }
        wysiwygViewModel.select(range: currentLinkData.range)
    }

    private func setLink() {
        guard let currentLinkData else { return }
        wysiwygViewModel.applyLinkOperation(.setLink(urlString: currentLinkData.url))
    }

    private func createLinkWithText() {
        guard let currentLinkData else { return }
        wysiwygViewModel.applyLinkOperation(.createLink(urlString: currentLinkData.url,
                                                        text: currentLinkData.text))
    }

    private func removeLinks() {
        wysiwygViewModel.applyLinkOperation(.removeLinks)
    }
}

private extension WysiwygComposerViewModel {
    /// Return true if the selection of the composer is currently located in a list.
    var isInList: Bool {
        actionStates[.orderedList] == .reversed || actionStates[.unorderedList] == .reversed
    }
}

private extension LinkAction {
    var url: String? {
        guard case .edit(let url) = self else {
            return nil
        }
        return url
    }
}
