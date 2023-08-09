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

struct CreatePollScreenCoordinatorParameters { }

enum CreatePollScreenCoordinatorAction {
    case done
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}

final class CreatePollScreenCoordinator: CoordinatorProtocol {
    private let parameters: CreatePollScreenCoordinatorParameters
    private var viewModel: CreatePollScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<CreatePollScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<CreatePollScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: CreatePollScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = CreatePollScreenViewModel()
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .done:
                self.actionsSubject.send(.done)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(CreatePollScreen(context: viewModel.context))
    }
}
