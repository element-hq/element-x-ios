//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct HomeScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let bugReportService: BugReportServiceProtocol
    let selectedRoomPublisher: CurrentValuePublisher<String?, Never>
    let appSettings: AppSettings
    let analyticsService: AnalyticsService
    let notificationManager: NotificationManagerProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum HomeScreenCoordinatorAction {
    case presentRoom(roomIdentifier: String)
    case presentRoomDetails(roomIdentifier: String)
    case presentReportRoom(roomIdentifier: String)
    case presentDeclineAndBlock(userID: String, roomID: String)
    case presentSpace(SpaceRoomListProxyProtocol)
    case roomLeft(roomIdentifier: String)
    case transferOwnership(roomIdentifier: String)
    case presentSettingsScreen
    case presentFeedbackScreen
    case presentSecureBackupSettings
    case presentRecoveryKeyScreen
    case presentEncryptionResetScreen
    case presentStartChatScreen
    case presentGlobalSearch
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
                                        selectedRoomPublisher: parameters.selectedRoomPublisher,
                                        appSettings: parameters.appSettings,
                                        analyticsService: parameters.analyticsService,
                                        notificationManager: parameters.notificationManager,
                                        userIndicatorController: parameters.userIndicatorController)
        bugReportService = parameters.bugReportService
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .presentRoom(let roomIdentifier):
                    actionsSubject.send(.presentRoom(roomIdentifier: roomIdentifier))
                case .presentRoomDetails(roomIdentifier: let roomIdentifier):
                    actionsSubject.send(.presentRoomDetails(roomIdentifier: roomIdentifier))
                case .presentReportRoom(let roomIdentifier):
                    actionsSubject.send(.presentReportRoom(roomIdentifier: roomIdentifier))
                case .presentDeclineAndBlock(let userID, let roomID):
                    actionsSubject.send(.presentDeclineAndBlock(userID: userID, roomID: roomID))
                case .presentSpace(let spaceRoomListProxy):
                    actionsSubject.send(.presentSpace(spaceRoomListProxy))
                case .roomLeft(roomIdentifier: let roomIdentifier):
                    actionsSubject.send(.roomLeft(roomIdentifier: roomIdentifier))
                case .presentFeedbackScreen:
                    actionsSubject.send(.presentFeedbackScreen)
                case .presentSettingsScreen:
                    actionsSubject.send(.presentSettingsScreen)
                case .presentSecureBackupSettings:
                    actionsSubject.send(.presentSecureBackupSettings)
                case .presentRecoveryKeyScreen:
                    actionsSubject.send(.presentRecoveryKeyScreen)
                case .presentEncryptionResetScreen:
                    actionsSubject.send(.presentEncryptionResetScreen)
                case .presentStartChatScreen:
                    actionsSubject.send(.presentStartChatScreen)
                case .presentGlobalSearch:
                    actionsSubject.send(.presentGlobalSearch)
                case .logout:
                    actionsSubject.send(.logout)
                case .transferOwnership(let roomIdentifier):
                    actionsSubject.send(.transferOwnership(roomIdentifier: roomIdentifier))
                }
            }
            .store(in: &cancellables)
    }
    
    // MARK: - Public
    
    func start() {
        #if !DEBUG
        // Note: bugReportService.isEnabled doesn't determine if a user has opted in to Analytics/Sentry.
        // Therefore we use lastCrashEventID as this will only be set if we have crash ID from Sentry.
        if bugReportService.crashedLastRun, bugReportService.lastCrashEventID != nil {
            viewModel.presentCrashedLastRunAlert()
        }
        #endif
    }
    
    func toPresentable() -> AnyView {
        AnyView(HomeScreen(context: viewModel.context))
    }
}
