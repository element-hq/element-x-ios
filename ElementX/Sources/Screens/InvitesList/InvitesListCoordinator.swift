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

struct InvitesListCoordinatorParameters {
    let promptType: InvitesListPromptType
}

enum InvitesListCoordinatorAction {
    case accept
    case cancel
    
    // Consider adding CustomStringConvertible conformance if the actions contain PII
}

final class InvitesListCoordinator: CoordinatorProtocol {
    private let parameters: InvitesListCoordinatorParameters
    private var viewModel: InvitesListViewModelProtocol
    private let actionsSubject: PassthroughSubject<InvitesListCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<InvitesListCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: InvitesListCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = InvitesListViewModel(promptType: parameters.promptType)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .accept:
                MXLog.info("User accepted the prompt.")
                self.actionsSubject.send(.accept)
            case .cancel:
                self.actionsSubject.send(.cancel)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(InvitesListScreen(context: viewModel.context))
    }
}
