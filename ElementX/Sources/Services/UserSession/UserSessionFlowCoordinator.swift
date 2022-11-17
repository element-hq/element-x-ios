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

import SwiftUI

enum UserSessionFlowCoordinatorAction {
    case signOut
}

class UserSessionFlowCoordinator: CoordinatorProtocol {
    private let stateMachine: UserSessionFlowCoordinatorStateMachine
    
    private let userSession: UserSessionProtocol
    private let navigationController: NavigationController
    private let bugReportService: BugReportServiceProtocol
    
    var callback: ((UserSessionFlowCoordinatorAction) -> Void)?
    
    init(userSession: UserSessionProtocol, navigationController: NavigationController, bugReportService: BugReportServiceProtocol) {
        stateMachine = UserSessionFlowCoordinatorStateMachine()
        self.userSession = userSession
        self.navigationController = navigationController
        self.bugReportService = bugReportService
        
        setupStateMachine()
        startObservingApplicationState()
    }
    
    func start() {
        stateMachine.processEvent(.start)
    }
    
    func stop() { }

    func isDisplayingRoomScreen(withRoomId roomId: String) -> Bool {
        stateMachine.isDisplayingRoomScreen(withRoomId: roomId)
    }

    func tryDisplayingRoomScreen(roomId: String) {
        stateMachine.processEvent(.showRoomScreen(roomId: roomId))
    }

    // MARK: - Private
    
    // swiftlint:disable:next cyclomatic_complexity
    private func setupStateMachine() {
        stateMachine.addTransitionHandler { [weak self] context in
            guard let self else { return }
            
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .start, .homeScreen):
                self.presentHomeScreen()
                
            case(.homeScreen, .showRoomScreen, .roomScreen(let roomId)):
                self.presentRoomWithIdentifier(roomId)
            case(.roomScreen, .dismissedRoomScreen, .homeScreen):
                break
                
            case (.homeScreen, .showSessionVerificationScreen, .sessionVerificationScreen):
                self.presentSessionVerification()
            case (.sessionVerificationScreen, .dismissedSessionVerificationScreen, .homeScreen):
                break
                
            case (.homeScreen, .showSettingsScreen, .settingsScreen):
                self.presentSettingsScreen()
            case (.settingsScreen, .dismissedSettingsScreen, .homeScreen):
                break
                
            case (.homeScreen, .feedbackScreen, .feedbackScreen):
                self.presentFeedbackScreen()
            case (.feedbackScreen, .dismissedFeedbackScreen, .homeScreen):
                break
                
            case (_, .resignActive, .suspended):
                self.pause()
            case (_, .becomeActive, _):
                self.resume()
                
            default:
                fatalError("Unknown transition: \(context)")
            }
        }
        
        stateMachine.addErrorHandler { context in
            fatalError("Failed transition with context: \(context)")
        }
    }

    private func startObservingApplicationState() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationWillResignActive),
                                               name: UIApplication.willResignActiveNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(applicationDidBecomeActive),
                                               name: UIApplication.didBecomeActiveNotification,
                                               object: nil)
    }
    
    private func presentHomeScreen() {
        userSession.clientProxy.startSync()

        let parameters = HomeScreenCoordinatorParameters(userSession: userSession,
                                                         attributedStringBuilder: AttributedStringBuilder(),
                                                         bugReportService: bugReportService,
                                                         navigationController: navigationController)
        let coordinator = HomeScreenCoordinator(parameters: parameters)

        coordinator.callback = { [weak self] action in
            guard let self else { return }

            switch action {
            case .presentRoomScreen(let roomIdentifier):
                self.stateMachine.processEvent(.showRoomScreen(roomId: roomIdentifier))
            case .presentSettingsScreen:
                self.stateMachine.processEvent(.showSettingsScreen)
            case .presentFeedbackScreen:
                self.stateMachine.processEvent(.feedbackScreen)
            case .presentSessionVerificationScreen:
                self.stateMachine.processEvent(.showSessionVerificationScreen)
            case .signOut:
                self.callback?(.signOut)
            }
        }

        navigationController.setRootCoordinator(coordinator)
    }
    
    // MARK: Rooms

    private func presentRoomWithIdentifier(_ roomIdentifier: String) {
        Task { @MainActor in
            guard let roomProxy = await userSession.clientProxy.roomForIdentifier(roomIdentifier) else {
                MXLog.error("Invalid room identifier: \(roomIdentifier)")
                return
            }
            let userId = userSession.clientProxy.userIdentifier

            let timelineItemFactory = RoomTimelineItemFactory(userID: userId,
                                                              mediaProvider: userSession.mediaProvider,
                                                              roomProxy: roomProxy,
                                                              attributedStringBuilder: AttributedStringBuilder())

            let timelineController = RoomTimelineController(userId: userId,
                                                            roomId: roomIdentifier,
                                                            timelineProvider: RoomTimelineProvider(roomProxy: roomProxy),
                                                            timelineItemFactory: timelineItemFactory,
                                                            mediaProvider: userSession.mediaProvider,
                                                            roomProxy: roomProxy)

            let parameters = RoomScreenCoordinatorParameters(navigationController: navigationController,
                                                             timelineController: timelineController,
                                                             mediaProvider: userSession.mediaProvider,
                                                             roomName: roomProxy.displayName ?? roomProxy.name,
                                                             roomAvatarUrl: roomProxy.avatarURL)
            let coordinator = RoomScreenCoordinator(parameters: parameters)
            
            navigationController.push(coordinator) { [weak self] in
                guard let self else { return }
                self.stateMachine.processEvent(.dismissedRoomScreen)
            }
        }
    }
        
    // MARK: Settings
    
    private func presentSettingsScreen() {
        let settingsNavigationController = NavigationController()
        
        let userNotificationController = UserNotificationController(rootCoordinator: settingsNavigationController)
        
        let parameters = SettingsCoordinatorParameters(navigationController: settingsNavigationController,
                                                       userNotificationController: userNotificationController,
                                                       userSession: userSession,
                                                       bugReportService: bugReportService)
        let settingsCoordinator = SettingsCoordinator(parameters: parameters)
        settingsCoordinator.callback = { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss:
                self.navigationController.dismissSheet()
            case .logout:
                self.navigationController.dismissSheet()
                self.callback?(.signOut)
            }
        }
        
        settingsNavigationController.setRootCoordinator(settingsCoordinator)
        
        navigationController.presentSheet(userNotificationController) { [weak self] in
            self?.stateMachine.processEvent(.dismissedSettingsScreen)
        }
    }
    
    // MARK: Session verification
    
    private func presentSessionVerification() {
        guard let sessionVerificationController = userSession.sessionVerificationController else {
            fatalError("The sessionVerificationController should aways be valid at this point")
        }
        
        let parameters = SessionVerificationCoordinatorParameters(sessionVerificationControllerProxy: sessionVerificationController)
        
        let coordinator = SessionVerificationCoordinator(parameters: parameters)
        
        coordinator.callback = { [weak self] in
            self?.navigationController.dismissSheet()
        }
        
        navigationController.presentSheet(coordinator) { [weak self] in
            self?.stateMachine.processEvent(.dismissedSessionVerificationScreen)
        }
    }
        
    // MARK: Bug reporting
    
    private func presentFeedbackScreen(for image: UIImage? = nil) {
        let feedbackNavigationController = NavigationController()
        
        let userNotificationController = UserNotificationController(rootCoordinator: feedbackNavigationController)
        
        let parameters = BugReportCoordinatorParameters(bugReportService: bugReportService,
                                                        userNotificationController: userNotificationController,
                                                        screenshot: image,
                                                        isModallyPresented: true)
        let coordinator = BugReportCoordinator(parameters: parameters)
        coordinator.completion = { [weak self] _ in
            self?.navigationController.dismissSheet()
        }

        feedbackNavigationController.setRootCoordinator(coordinator)
        
        navigationController.presentSheet(userNotificationController) { [weak self] in
            self?.stateMachine.processEvent(.dismissedFeedbackScreen)
        }
    }
    
    // MARK: - Application State

    private func pause() {
        userSession.clientProxy.stopSync()
    }

    private func resume() {
        userSession.clientProxy.startSync()
    }

    @objc
    private func applicationWillResignActive() {
        stateMachine.processEvent(.resignActive)
    }

    @objc
    private func applicationDidBecomeActive() {
        stateMachine.processEvent(.becomeActive)
    }
}
