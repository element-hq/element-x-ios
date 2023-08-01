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
    var callback: ((ComposerToolbarViewAction) -> Void)?

    private var focusedSubject = PassthroughSubject<Bool, Never>()
    private var composerModeSubject = PassthroughSubject<RoomScreenComposerMode, Never>()

    init() {
        super.init(initialViewState: ComposerToolbarViewState(bindings: .init(composerText: "", composerFocused: false)))

        context.$viewState
            .map(\.composerMode)
            .sink { [weak self] in self?.composerModeSubject.send($0) }
            .store(in: &cancellables)

        context.$viewState
            .map(\.bindings.composerFocused)
            .sink { [weak self] in self?.focusedSubject.send($0) }
            .store(in: &cancellables)
    }

    override func process(viewAction: ComposerToolbarViewAction) {
        callback?(viewAction)
    }
}

extension ComposerToolbarViewModel: RoomScreenComposerActionHandlerProtocol {
    var focused: PassthroughSubject<Bool, Never> {
        focusedSubject
    }

    var composerMode: PassthroughSubject<RoomScreenComposerMode, Never> {
        composerModeSubject
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

    private func set(mode: RoomScreenComposerMode) {
        guard mode != state.composerMode else { return }

        state.composerMode = mode
        if mode != .default {
            // Focus composer when switching to reply/edit
            state.bindings.composerFocused = true
        }
    }

    private func set(text: String?) {
        guard let text else { return }

        state.bindings.composerText = text
    }
}
