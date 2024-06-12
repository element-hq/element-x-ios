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

final class AuthenticationStartScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AuthenticationStartScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<AuthenticationStartScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<AuthenticationStartScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init() {
        viewModel = AuthenticationStartScreenViewModel()
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .loginManually:
                    actionsSubject.send(.loginManually)
                case .loginWithQR:
                    actionsSubject.send(.loginWithQR)
                case .reportProblem:
                    actionsSubject.send(.reportProblem)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(AuthenticationStartScreen(context: viewModel.context))
    }
}
