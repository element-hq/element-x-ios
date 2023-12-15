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

import Combine
import SwiftUI

struct PollFormScreenCoordinatorParameters {
    let mode: PollFormMode
}

enum PollFormScreenCoordinatorAction {
    case cancel
    case delete
    case submit(question: String, options: [String], pollKind: Poll.Kind)
}

final class PollFormScreenCoordinator: CoordinatorProtocol {
    private var viewModel: PollFormScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<PollFormScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<PollFormScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: PollFormScreenCoordinatorParameters) {
        viewModel = PollFormScreenViewModel(mode: parameters.mode)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .cancel:
                self.actionsSubject.send(.cancel)
            case .delete:
                self.actionsSubject.send(.delete)
            case let .submit(question, options, pollKind):
                self.actionsSubject.send(.submit(question: question, options: options, pollKind: pollKind))
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(PollFormScreen(context: viewModel.context))
    }
}
