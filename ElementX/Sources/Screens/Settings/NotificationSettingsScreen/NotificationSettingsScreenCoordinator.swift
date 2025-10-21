//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct NotificationSettingsScreenCoordinatorParameters {
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let userSession: UserSessionProtocol
    let userNotificationCenter: UserNotificationCenterProtocol
    let isModallyPresented: Bool
    let appSettings: AppSettings
}

enum NotificationSettingsScreenCoordinatorAction {
    case close
}

final class NotificationSettingsScreenCoordinator: CoordinatorProtocol {
    private let parameters: NotificationSettingsScreenCoordinatorParameters
    private var viewModel: NotificationSettingsScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<NotificationSettingsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    private var navigationStackCoordinator: NavigationStackCoordinator? {
        parameters.navigationStackCoordinator
    }
    
    var actions: AnyPublisher<NotificationSettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: NotificationSettingsScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = NotificationSettingsScreenViewModel(appSettings: parameters.appSettings,
                                                        userNotificationCenter: parameters.userNotificationCenter,
                                                        notificationSettingsProxy: parameters.userSession.clientProxy.notificationSettings,
                                                        isModallyPresented: parameters.isModallyPresented)
    }
    
    func start() {
        viewModel.fetchInitialContent()
        
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                self.actionsSubject.send(.close)
            case .editDefaultMode(let chatType):
                self.presentEditScreen(chatType: chatType)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(NotificationSettingsScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func presentEditScreen(chatType: NotificationSettingsChatType) {
        let editSettingsParameters = NotificationSettingsEditScreenCoordinatorParameters(navigationStackCoordinator: parameters.navigationStackCoordinator,
                                                                                         chatType: chatType,
                                                                                         userSession: parameters.userSession)
        let editSettingsCoordinator = NotificationSettingsEditScreenCoordinator(parameters: editSettingsParameters)
        navigationStackCoordinator?.push(editSettingsCoordinator)
    }
}
