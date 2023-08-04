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

typealias ComposerToolbarViewModelType = StateStoreViewModel<ComposerToolbarViewState, ComposerToolbarViewAction>

final class ComposerToolbarViewModel: ComposerToolbarViewModelType, ComposerToolbarViewModelProtocol {
    var callback: ((ComposerToolbarViewModelAction) -> Void)?

    init() {
        super.init(initialViewState: ComposerToolbarViewState(bindings: .init(composerText: "", composerFocused: false)))

        context.$viewState
            .map(\.composerMode)
            .removeDuplicates()
            .sink { [weak self] in self?.callback?(.composerModeChanged(mode: $0)) }
            .store(in: &cancellables)

        context.$viewState
            .map(\.bindings.composerFocused)
            .removeDuplicates()
            .sink { [weak self] in self?.callback?(.focusedChanged(isFocused: $0)) }
            .store(in: &cancellables)
    }

    // MARK: - Public

    override func process(viewAction: ComposerToolbarViewAction) {
        switch viewAction {
        case .sendMessage(let message, let mode):
            callback?(.sendMessage(message: message, mode: mode))
        case .cancelReply:
            set(mode: .default)
        case .cancelEdit:
            set(mode: .default)
            set(text: "")
        case .displayCameraPicker:
            callback?(.displayCameraPicker)
        case .displayMediaPicker:
            callback?(.displayMediaPicker)
        case .displayDocumentPicker:
            callback?(.displayDocumentPicker)
        case .displayLocationPicker:
            callback?(.displayLocationPicker)
        case .handlePasteOrDrop(let provider):
            callback?(.handlePasteOrDrop(provider: provider))
        }
    }

    func process(composerAction: RoomScreenComposerAction) {
        switch composerAction {
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
        state.bindings.composerText = text
    }
}
