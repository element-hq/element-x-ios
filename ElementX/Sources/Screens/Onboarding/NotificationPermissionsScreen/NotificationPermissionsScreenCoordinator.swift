//
// Copyright 2021 New Vector Ltd
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

struct NotificationPermissionsScreenCoordinatorParameters {
    let notificationManager: NotificationManagerProtocol
}

enum NotificationPermissionsScreenCoordinatorAction {
    case done
}

final class NotificationPermissionsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: NotificationPermissionsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<NotificationPermissionsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<NotificationPermissionsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: NotificationPermissionsScreenCoordinatorParameters) {
        viewModel = NotificationPermissionsScreenViewModel(notificationManager: parameters.notificationManager)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .done:
                    actionsSubject.send(.done)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(NotificationPermissionsScreen(context: viewModel.context))
    }
}
