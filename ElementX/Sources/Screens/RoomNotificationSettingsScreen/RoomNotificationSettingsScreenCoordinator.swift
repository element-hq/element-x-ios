//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct RoomNotificationSettingsScreenCoordinatorParameters {
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let notificationSettingsProxy: NotificationSettingsProxyProtocol
    let roomProxy: JoinedRoomProxyProtocol
    let displayAsUserDefinedRoomSettings: Bool
}

enum RoomNotificationSettingsScreenCoordinatorAction {
    case presentGlobalNotificationSettingsScreen
}

final class RoomNotificationSettingsScreenCoordinator: CoordinatorProtocol {
    private let parameters: RoomNotificationSettingsScreenCoordinatorParameters
    private var viewModel: RoomNotificationSettingsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<RoomNotificationSettingsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
        
    var actions: AnyPublisher<RoomNotificationSettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
        
    init(parameters: RoomNotificationSettingsScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: parameters.notificationSettingsProxy,
                                                            roomProxy: parameters.roomProxy,
                                                            displayAsUserDefinedRoomSettings: parameters.displayAsUserDefinedRoomSettings)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            switch action {
            case .openGlobalSettings:
                self?.actionsSubject.send(.presentGlobalNotificationSettingsScreen)
            case .dismiss:
                self?.parameters.navigationStackCoordinator?.pop(animated: true)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        if parameters.displayAsUserDefinedRoomSettings {
            return AnyView(RoomNotificationSettingsUserDefinedScreen(context: viewModel.context))
        } else {
            return AnyView(RoomNotificationSettingsScreen(context: viewModel.context))
        }
    }
}
