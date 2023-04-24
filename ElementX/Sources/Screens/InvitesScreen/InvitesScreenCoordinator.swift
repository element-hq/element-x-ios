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

struct InvitesScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
}

enum InvitesScreenCoordinatorAction {
    case openRoom(withIdentifier: String)
}

final class InvitesScreenCoordinator: CoordinatorProtocol {
    private let parameters: InvitesScreenCoordinatorParameters
    private var viewModel: InvitesScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<InvitesScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<InvitesScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: InvitesScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = InvitesScreenViewModel(userSession: parameters.userSession)
    }
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .openRoom(let roomID):
                    self.actionsSubject.send(.openRoom(withIdentifier: roomID))
                }
            }
            .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(InvitesScreen(context: viewModel.context))
    }
}
