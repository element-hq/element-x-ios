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

struct NotificationSettingsScreenCoordinatorParameters {
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let userSession: UserSessionProtocol
    let userNotificationCenter: UserNotificationCenterProtocol
    let notificationSettings: NotificationSettingsProxyProtocol
    let isModallyPresented: Bool
}

enum NotificationSettingsScreenCoordinatorAction {
    case close
}

final class NotificationSettingsScreenCoordinator: CoordinatorProtocol {
    private let parameters: NotificationSettingsScreenCoordinatorParameters
    private var viewModel: NotificationSettingsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<NotificationSettingsScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    private var navigationStackCoordinator: NavigationStackCoordinator? {
        parameters.navigationStackCoordinator
    }
    
    var actions: AnyPublisher<NotificationSettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: NotificationSettingsScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = NotificationSettingsScreenViewModel(userSession: parameters.userSession,
                                                        appSettings: ServiceLocator.shared.settings,
                                                        userNotificationCenter: parameters.userNotificationCenter,
                                                        notificationSettingsProxy: parameters.notificationSettings,
                                                        isModallyPresented: parameters.isModallyPresented)
    }
    
    func start() {
        viewModel.fetchInitialContent()
        
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                self.actionsSubject.send(.close)
            case .editDefaultMode(let isDirect):
                self.presentEditScreen(isDirect: isDirect)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(NotificationSettingsScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func presentEditScreen(isDirect: Bool) {
        let editSettingsParameters = NotificationSettingsEditScreenCoordinatorParameters(navigationStackCoordinator: parameters.navigationStackCoordinator,
                                                                                         isDirect: isDirect,
                                                                                         userSession: parameters.userSession,
                                                                                         notificationSettings: parameters.notificationSettings)
        let editSettingsCoordinator = NotificationSettingsEditScreenCoordinator(parameters: editSettingsParameters)
        navigationStackCoordinator?.push(editSettingsCoordinator)
    }
}
