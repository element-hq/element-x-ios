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
import WysiwygComposer

typealias ComposerToolbarViewModelType = StateStoreViewModel<ComposerToolbarViewState, ComposerToolbarViewAction>

final class ComposerToolbarViewModel: ComposerToolbarViewModelType, ComposerToolbarViewModelProtocol {
    private let wysiwygViewModel: WysiwygComposerViewModel
    private let actionsSubject: PassthroughSubject<ComposerToolbarViewModelAction, Never> = .init()
    var actions: AnyPublisher<ComposerToolbarViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(wysiwygViewModel: WysiwygComposerViewModel) {
        self.wysiwygViewModel = wysiwygViewModel

        super.init(initialViewState: ComposerToolbarViewState(bindings: .init(composerFocused: false)))

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
    }

    // MARK: - Public

    override func process(viewAction: ComposerToolbarViewAction) {
        switch viewAction {
        case .composerAppeared:
            wysiwygViewModel.setup()
        case .sendMessage:
            guard !state.sendButtonDisabled else { return }

            actionsSubject.send(.sendMessage(message: wysiwygViewModel.content.markdown, mode: state.composerMode))
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
        case .handlePasteOrDrop(let provider):
            actionsSubject.send(.handlePasteOrDrop(provider: provider))
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
        wysiwygViewModel.setMarkdownContent(text)
    }
}
