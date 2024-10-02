//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct NotificationSettingsEditScreenCoordinatorParameters {
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let chatType: NotificationSettingsChatType
    let userSession: UserSessionProtocol
    let notificationSettings: NotificationSettingsProxyProtocol
}

final class NotificationSettingsEditScreenCoordinator: CoordinatorProtocol {
    private let parameters: NotificationSettingsEditScreenCoordinatorParameters
    private var viewModel: NotificationSettingsEditScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: NotificationSettingsEditScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = NotificationSettingsEditScreenViewModel(chatType: parameters.chatType,
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
        guard case let .joined(roomProxy) = await parameters.userSession.clientProxy.roomForIdentifier(roomID) else { return }
         
        let roomNotificationSettingsParameters = RoomNotificationSettingsScreenCoordinatorParameters(navigationStackCoordinator: parameters.navigationStackCoordinator,
                                                                                                     notificationSettingsProxy: parameters.notificationSettings,
                                                                                                     roomProxy: roomProxy,
                                                                                                     displayAsUserDefinedRoomSettings: true)
        let roomNotificationSettingsCoordinator = RoomNotificationSettingsScreenCoordinator(parameters: roomNotificationSettingsParameters)
        parameters.navigationStackCoordinator?.push(roomNotificationSettingsCoordinator)
    }
}
