//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct HomeScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let bugReportService: BugReportServiceProtocol
    let selectedRoomPublisher: CurrentValuePublisher<String?, Never>
}

enum HomeScreenCoordinatorAction {
    case presentRoom(roomIdentifier: String)
    case presentRoomDetails(roomIdentifier: String)
    case roomLeft(roomIdentifier: String)
    case presentSettingsScreen
    case presentFeedbackScreen
    case presentSecureBackupSettings
    case presentStartChatScreen
    case presentGlobalSearch
    case presentRoomDirectorySearch
    case logoutWithoutConfirmation
    case logout
}

final class HomeScreenCoordinator: CoordinatorProtocol {
    private var viewModel: HomeScreenViewModelProtocol
    // periphery:ignore - only used in release builds
    private let bugReportService: BugReportServiceProtocol
    
    private let actionsSubject: PassthroughSubject<HomeScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<HomeScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: HomeScreenCoordinatorParameters) {
        viewModel = HomeScreenViewModel(userSession: parameters.userSession,
                                        analyticsService: ServiceLocator.shared.analytics,
                                        appSettings: ServiceLocator.shared.settings,
                                        selectedRoomPublisher: parameters.selectedRoomPublisher,
                                        userIndicatorController: ServiceLocator.shared.userIndicatorController)
        bugReportService = parameters.bugReportService
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .presentRoom(let roomIdentifier):
                    actionsSubject.send(.presentRoom(roomIdentifier: roomIdentifier))
                case .presentRoomDetails(roomIdentifier: let roomIdentifier):
                    actionsSubject.send(.presentRoomDetails(roomIdentifier: roomIdentifier))
                case .roomLeft(roomIdentifier: let roomIdentifier):
                    actionsSubject.send(.roomLeft(roomIdentifier: roomIdentifier))
                case .presentFeedbackScreen:
                    actionsSubject.send(.presentFeedbackScreen)
                case .presentSettingsScreen:
                    actionsSubject.send(.presentSettingsScreen)
                case .presentSecureBackupSettings:
                    actionsSubject.send(.presentSecureBackupSettings)
                case .presentStartChatScreen:
                    actionsSubject.send(.presentStartChatScreen)
                case .presentGlobalSearch:
                    actionsSubject.send(.presentGlobalSearch)
                case .presentRoomDirectorySearch:
                    actionsSubject.send(.presentRoomDirectorySearch)
                case .logoutWithoutConfirmation:
                    actionsSubject.send(.logoutWithoutConfirmation)
                case .logout:
                    actionsSubject.send(.logout)
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    func start() {
        #if !DEBUG
        if bugReportService.crashedLastRun {
            viewModel.presentCrashedLastRunAlert()
        }
        #endif
    }
    
    func toPresentable() -> AnyView {
        AnyView(HomeScreen(context: viewModel.context))
    }
}
