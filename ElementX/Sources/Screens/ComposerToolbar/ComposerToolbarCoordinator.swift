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
import SwiftUI

final class ComposerToolbarCoordinator: CoordinatorProtocol {
    private var viewModel: ComposerToolbarViewModelProtocol
    private var cancellables = Set<AnyCancellable>()

    private let actionsSubject = PassthroughSubject<ComposerToolbarViewAction, Never>()
    var actions: AnyPublisher<ComposerToolbarViewAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    func set(composerActions: AnyPublisher<RoomScreenComposerAction, Never>) {
        composerActions
            .sink { [weak self] action in
                guard let self else { return }

                viewModel.process(composerAction: action)
            }
            .store(in: &cancellables)
    }

    init() {
        viewModel = ComposerToolbarViewModel()
    }

    func start() {
        viewModel.callback = { [weak self] action in
            guard let self else { return }

            self.actionsSubject.send(action)
        }
    }

    func toPresentable() -> AnyView {
        AnyView(ComposerToolbar(context: viewModel.context))
    }
}
