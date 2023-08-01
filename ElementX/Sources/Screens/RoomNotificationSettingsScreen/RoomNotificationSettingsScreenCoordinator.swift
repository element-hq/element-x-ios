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

struct RoomNotificationSettingsScreenCoordinatorParameters {
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let notificationSettingsProxy: NotificationSettingsProxyProtocol
    let roomProxy: RoomProxyProtocol
}

final class RoomNotificationSettingsScreenCoordinator: CoordinatorProtocol {
    private let parameters: RoomNotificationSettingsScreenCoordinatorParameters
    private var viewModel: RoomNotificationSettingsScreenViewModelProtocol
    private var cancellables: Set<AnyCancellable> = .init()
    
    private var navigationStackCoordinator: NavigationStackCoordinator? {
        parameters.navigationStackCoordinator
    }
        
    init(parameters: RoomNotificationSettingsScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: parameters.notificationSettingsProxy,
                                                            roomProxy: parameters.roomProxy)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            switch action {
            case .openGlobalSettings:
                self?.openGlobalSettings()
            }
        }.store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(RoomNotificationSettingsScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func openGlobalSettings() {
        let navigationStackCoordinator = NavigationStackCoordinator()
        let notificationSettingsScreenParameters = NotificationSettingsScreenCoordinatorParameters(userNotificationCenter: UNUserNotificationCenter.current(),
                                                                                                   notificationSettings: parameters.notificationSettingsProxy,
                                                                                                   isModallyPresented: true)
        let notificationSettingsScreenCoordinator = NotificationSettingsScreenCoordinator(parameters: notificationSettingsScreenParameters)
        notificationSettingsScreenCoordinator.completion = { [weak self] _ in
            self?.navigationStackCoordinator?.setSheetCoordinator(nil)
        }
        navigationStackCoordinator.setRootCoordinator(notificationSettingsScreenCoordinator)
        self.navigationStackCoordinator?.setSheetCoordinator(navigationStackCoordinator)
    }
}
