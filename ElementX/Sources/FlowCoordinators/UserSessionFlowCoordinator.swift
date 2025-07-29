//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Compound
import MatrixRustSDK
import SwiftUI

enum UserSessionFlowCoordinatorAction {
    case logout
    case clearCache
    /// Logout without a confirmation. The user forgot their PIN.
    case forceLogout
}

class UserSessionFlowCoordinator: FlowCoordinatorProtocol {
    private let userSession: UserSessionProtocol
    private let navigationRootCoordinator: NavigationRootCoordinator
    private let navigationTabCoordinator: NavigationTabCoordinator
    
    private let chatsFlowCoordinator: ChatsFlowCoordinator
    
    private let actionsSubject: PassthroughSubject<UserSessionFlowCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<UserSessionFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables: Set<AnyCancellable> = []
    
    init(userSession: UserSessionProtocol,
         navigationRootCoordinator: NavigationRootCoordinator,
         appLockService: AppLockServiceProtocol,
         bugReportService: BugReportServiceProtocol,
         elementCallService: ElementCallServiceProtocol,
         timelineControllerFactory: TimelineControllerFactoryProtocol,
         appMediator: AppMediatorProtocol,
         appSettings: AppSettings,
         appHooks: AppHooks,
         analytics: AnalyticsService,
         notificationManager: NotificationManagerProtocol,
         isNewLogin: Bool) {
        self.userSession = userSession
        self.navigationRootCoordinator = navigationRootCoordinator
        
        navigationTabCoordinator = NavigationTabCoordinator()
        navigationRootCoordinator.setRootCoordinator(navigationTabCoordinator)
        
        let chatsSplitCoordinator = NavigationSplitCoordinator(placeholderCoordinator: PlaceholderScreenCoordinator())
        chatsFlowCoordinator = ChatsFlowCoordinator(userSession: userSession,
                                                    navigationSplitCoordinator: chatsSplitCoordinator,
                                                    appLockService: appLockService,
                                                    bugReportService: bugReportService,
                                                    elementCallService: elementCallService,
                                                    timelineControllerFactory: timelineControllerFactory,
                                                    appMediator: appMediator,
                                                    appSettings: appSettings,
                                                    appHooks: appHooks,
                                                    analytics: analytics,
                                                    notificationManager: notificationManager,
                                                    isNewLogin: isNewLogin)
        
        navigationTabCoordinator.setTabs([
            .init(coordinator: chatsSplitCoordinator, title: L10n.screenHomeTabChats, icon: \.chat, selectedIcon: \.chatSolid),
            .init(coordinator: BlankFormCoordinator(), title: L10n.screenHomeTabSpaces, icon: \.space, selectedIcon: \.spaceSolid)
        ])
        
        chatsFlowCoordinator.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .logout:
                    actionsSubject.send(.logout)
                case .clearCache:
                    actionsSubject.send(.clearCache)
                case .forceLogout:
                    actionsSubject.send(.forceLogout)
                }
            }
            .store(in: &cancellables)
    }
    
    func start() {
        chatsFlowCoordinator.start()
    }
    
    func stop() {
        chatsFlowCoordinator.stop()
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        chatsFlowCoordinator.handleAppRoute(appRoute, animated: animated)
    }
    
    func clearRoute(animated: Bool) {
        chatsFlowCoordinator.clearRoute(animated: animated)
    }
    
    #warning("Should this be a publisher instead??")
    func isDisplayingRoomScreen(withRoomID roomID: String) -> Bool {
        chatsFlowCoordinator.isDisplayingRoomScreen(withRoomID: roomID)
    }
}
