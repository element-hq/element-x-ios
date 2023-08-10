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

struct NotificationSettingsEditScreenCoordinatorParameters {
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let isDirect: Bool
    let userSession: UserSessionProtocol
    let notificationSettings: NotificationSettingsProxyProtocol
}

enum NotificationSettingsEditScreenCoordinatorAction { }

final class NotificationSettingsEditScreenCoordinator: CoordinatorProtocol {
    private let parameters: NotificationSettingsEditScreenCoordinatorParameters
    private var viewModel: NotificationSettingsEditScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<NotificationSettingsEditScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
    var actions: AnyPublisher<NotificationSettingsEditScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: NotificationSettingsEditScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = NotificationSettingsEditScreenViewModel(isDirect: parameters.isDirect,
                                                            userSession: parameters.userSession,
                                                            notificationSettingsProxy: parameters.notificationSettings)
    }
    
    func start() {
        viewModel.fetchInitialContent()
        
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .requestRoomNotificationSettingsPresentation(let roomID):
                Task { await self.presentRoomNotificationSettings(roomID: roomID) }
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(NotificationSettingsEditScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func presentRoomNotificationSettings(roomID: String) async {
        guard let roomProxy = await parameters.userSession.clientProxy.roomForIdentifier(roomID) else { return }
         
        let roomNotificationSettingsParameters = RoomNotificationSettingsScreenCoordinatorParameters(navigationStackCoordinator: parameters.navigationStackCoordinator,
                                                                                                     notificationSettingsProxy: parameters.notificationSettings,
                                                                                                     roomProxy: roomProxy,
                                                                                                     displayAsGlobalCustomRoomSettings: true)
        let roomNotificationSettingsCoordinator = RoomNotificationSettingsScreenCoordinator(parameters: roomNotificationSettingsParameters)
        parameters.navigationStackCoordinator?.push(roomNotificationSettingsCoordinator)
    }
}
