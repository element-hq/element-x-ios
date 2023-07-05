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

struct NotificationsSettingsScreenCoordinatorParameters {
    let userNotificationCenter: UserNotificationCenterProtocol
}

enum NotificationsSettingsScreenCoordinatorAction { }

final class NotificationsSettingsScreenCoordinator: CoordinatorProtocol {
    private let parameters: NotificationsSettingsScreenCoordinatorParameters
    private var viewModel: NotificationsSettingsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<NotificationsSettingsScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<NotificationsSettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: NotificationsSettingsScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = NotificationsSettingsScreenViewModel(appSettings: ServiceLocator.shared.settings,
                                                         userNotificationCenter: parameters.userNotificationCenter)
    }
    
    func start() { }
        
    func toPresentable() -> AnyView {
        AnyView(NotificationsSettingsScreen(context: viewModel.context))
    }
}
