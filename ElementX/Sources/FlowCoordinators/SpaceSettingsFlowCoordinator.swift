//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import SwiftState

enum SpaceSettingsFlowCoordinatorAction {
    case finished(leftRoom: Bool)
    case presentCallScreen(roomProxy: JoinedRoomProxyProtocol)
    case verifyUser(userID: String)
}

final class SpaceSettingsFlowCoordinator: FlowCoordinatorProtocol {
    indirect enum State: StateType {
        /// The state machine hasn't started.
        case initial
        /// The space settings screen
        case spaceSettings
        /// The edit details screen presented modally
        case editDetailsScreen
        /// The security and privacy screen
        case securityAndPrivacy
        /// The edit address screen
        case editAddress
        /// The manage authorized spaces screen
        case manageAuthorizedSpacesScreen
        /// The screen that allows a user to transfer their ownership of the space.
        case transferOwnership
        
        /// Other flows
        /// The roles and permissions screen
        case rolesAndPermissionsFlow
        /// The members flow screen
        case membersFlow
    }
    
    enum Event: EventType {
        case start
        
        case presentSpaceSettings
        
        case presentEditDetailsScreen
        case dismissedEditDetailsScreen
        
        case presentSecurityAndPrivacyScreen
        case dismissedSecurityAndPrivacyScreen
        
        case presentEditAddress
        case dismissedEditAddress
        
        case presentManageAuthorizedSpacesScreen
        case dismissedManageAuthorizedSpacesScreen

        case presentTransferOwnership
        case dismissedTransferOwnership
        
        // Other flows
        case startMembersListFlow
        case stopMembersListFlow
        
        case startRolesAndPermissionsFlow
        case stopRolesAndPermissionsFlow
    }
    
    private let roomProxy: JoinedRoomProxyProtocol
    private let navigationStackCoordinator: NavigationStackCoordinator
    private let initialCoordinator: CoordinatorProtocol?
    private let flowParameters: CommonFlowParameters
    
    private let stateMachine: StateMachine<State, Event>
    private var cancellables = Set<AnyCancellable>()
    
    private var membersFlowCoordinator: RoomMembersFlowCoordinator?
    private var rolesAndPermissionsFlowCoordinator: RoomRolesAndPermissionsFlowCoordinator?
    
    private var childFlowCoordinator: FlowCoordinatorProtocol?
    
    private let actionsSubject: PassthroughSubject<SpaceSettingsFlowCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<SpaceSettingsFlowCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
        
    init(roomProxy: JoinedRoomProxyProtocol,
         navigationStackCoordinator: NavigationStackCoordinator,
         flowParameters: CommonFlowParameters) {
        self.roomProxy = roomProxy
        self.flowParameters = flowParameters
        self.navigationStackCoordinator = navigationStackCoordinator
        initialCoordinator = navigationStackCoordinator.stackCoordinators.last ?? navigationStackCoordinator.rootCoordinator
        
        stateMachine = .init(state: .initial)
        configureStateMachine()
    }
    
    func start(animated: Bool) {
        stateMachine.tryEvent(.presentSpaceSettings, userInfo: animated)
    }
    
    func handleAppRoute(_ appRoute: AppRoute, animated: Bool) {
        fatalError("Not implemented yet")
    }
    
    func clearRoute(animated: Bool) {
        childFlowCoordinator?.clearRoute(animated: animated)
        navigationStackCoordinator.setSheetCoordinator(nil, animated: animated)
        
        guard let initialCoordinator else {
            return
        }
        navigationStackCoordinator.pop(to: initialCoordinator, animated: animated)
    }
    
    private func configureStateMachine() {
        stateMachine.addRouteMapping { event, fromState, _ in
            switch (fromState, event) {
            case (.initial, .presentSpaceSettings):
                return .spaceSettings
                
            case (.spaceSettings, .presentEditDetailsScreen):
                return .editDetailsScreen
            case (.editDetailsScreen, .dismissedEditDetailsScreen):
                return .spaceSettings
                
            case (.spaceSettings, .presentSecurityAndPrivacyScreen):
                return .securityAndPrivacy
            case (.securityAndPrivacy, .dismissedSecurityAndPrivacyScreen):
                return .spaceSettings
                
            case (.securityAndPrivacy, .presentEditAddress):
                return .editAddress
            case (.editAddress, .dismissedEditAddress):
                return .securityAndPrivacy
                
            case (.securityAndPrivacy, .presentManageAuthorizedSpacesScreen):
                return .manageAuthorizedSpacesScreen
            case (.manageAuthorizedSpacesScreen, .dismissedManageAuthorizedSpacesScreen):
                return .securityAndPrivacy

            case (.spaceSettings, .presentTransferOwnership):
                return .transferOwnership
            case (.transferOwnership, .dismissedTransferOwnership):
                return .spaceSettings
                
            case (.spaceSettings, .startMembersListFlow):
                return .membersFlow
            case (.membersFlow, .stopMembersListFlow):
                return .spaceSettings
                
            case (.spaceSettings, .startRolesAndPermissionsFlow):
                return .rolesAndPermissionsFlow
            case (.rolesAndPermissionsFlow, .stopRolesAndPermissionsFlow):
                return .spaceSettings
                
            default:
                return nil
            }
        }
        
        stateMachine.addAnyHandler(.any => .any) { [weak self] context in
            guard let self else { return }
            let animated = context.userInfo as? Bool ?? true
            switch (context.fromState, context.event, context.toState) {
            case (.initial, .presentSpaceSettings, .spaceSettings):
                presentSpaceSettings(animated: animated)
                
            case (.spaceSettings, .presentEditDetailsScreen, .editDetailsScreen):
                presentEditDetailsScreen()
                
            case (.editDetailsScreen, .dismissedEditDetailsScreen, .spaceSettings):
                break
                
            case (.spaceSettings, .presentSecurityAndPrivacyScreen, .securityAndPrivacy):
                presentSecurityAndPrivacyScreen()
            case (.securityAndPrivacy, .dismissedSecurityAndPrivacyScreen, .spaceSettings):
                break
                
            case (.securityAndPrivacy, .presentEditAddress, .editAddress):
                presentEditAddressScreen()
            case (.editAddress, .dismissedEditAddress, .securityAndPrivacy):
                break
                
            case (.securityAndPrivacy, .presentManageAuthorizedSpacesScreen, .manageAuthorizedSpacesScreen):
                guard let selection = context.userInfo as? AuthorizedSpacesSelection else {
                    fatalError("AuthorizedSpacesSelection expected as userInfo")
                }
                presentManageAuthorizedSpacesScreen(selection: selection)
            case (.manageAuthorizedSpacesScreen, .dismissedManageAuthorizedSpacesScreen, .securityAndPrivacy):
                break

            case (.spaceSettings, .presentTransferOwnership, .transferOwnership):
                presentTransferOwnershipScreen()
            case (.transferOwnership, .dismissedTransferOwnership, .spaceSettings):
                break

            case (.spaceSettings, .startMembersListFlow, .membersFlow):
                startMembersListFlow()
            case (.membersFlow, .stopMembersListFlow, .spaceSettings):
                childFlowCoordinator = nil
                
            case (.spaceSettings, .startRolesAndPermissionsFlow, .rolesAndPermissionsFlow):
                startRolesAndPermissionsFlow()
            case (.rolesAndPermissionsFlow, .stopRolesAndPermissionsFlow, .spaceSettings):
                childFlowCoordinator = nil
                
            default:
                fatalError("Unhandled transition")
            }
        }
    }
    
    private func presentSpaceSettings(animated: Bool) {
        let coordinator = RoomDetailsScreenCoordinator(parameters: .init(roomProxy: roomProxy,
                                                                         userSession: flowParameters.userSession,
                                                                         analyticsService: flowParameters.analytics,
                                                                         userIndicatorController: flowParameters.userIndicatorController,
                                                                         notificationSettings: flowParameters.userSession.clientProxy.notificationSettings,
                                                                         attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                                                         appSettings: flowParameters.appSettings))
        
        var leftRoom = false
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .presentRoomDetailsEditScreen:
                stateMachine.tryEvent(.presentEditDetailsScreen)
            case .presentSecurityAndPrivacyScreen:
                stateMachine.tryEvent(.presentSecurityAndPrivacyScreen)
            case .presentRoomMembersList:
                stateMachine.tryEvent(.startMembersListFlow)
            case .presentRolesAndPermissionsScreen:
                stateMachine.tryEvent(.startRolesAndPermissionsFlow)
            case .leftRoom:
                leftRoom = true
                navigationStackCoordinator.pop()
            case .transferOwnership:
                stateMachine.tryEvent(.presentTransferOwnership)
            case .presentRecipientDetails, .presentNotificationSettingsScreen, .presentReportRoomScreen,
                 .presentInviteUsersScreen, .presentPollsHistory, .presentCall,
                 .presentPinnedEventsTimeline, .presentMediaEventsTimeline, .presentKnockingRequestsListScreen:
                fatalError("Not handled in the space context")
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator, animated: animated) { [weak self] in
            self?.actionsSubject.send(.finished(leftRoom: leftRoom))
        }
    }
    
    private func presentEditDetailsScreen() {
        let stackCoordinator = NavigationStackCoordinator()
        let parameters = RoomDetailsEditScreenCoordinatorParameters(roomProxy: roomProxy,
                                                                    userSession: flowParameters.userSession,
                                                                    mediaUploadingPreprocessor: MediaUploadingPreprocessor(appSettings: flowParameters.appSettings),
                                                                    navigationStackCoordinator: stackCoordinator,
                                                                    userIndicatorController: flowParameters.userIndicatorController,
                                                                    orientationManager: flowParameters.appMediator.windowManager,
                                                                    appSettings: flowParameters.appSettings)
        
        let coordinator = RoomDetailsEditScreenCoordinator(parameters: parameters)
        
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss:
                navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedEditDetailsScreen)
        }
    }
    
    private func presentSecurityAndPrivacyScreen() {
        let coordinator = SecurityAndPrivacyScreenCoordinator(parameters: .init(roomProxy: roomProxy,
                                                                                clientProxy: flowParameters.userSession.clientProxy,
                                                                                userIndicatorController: flowParameters.userIndicatorController,
                                                                                appSetting: flowParameters.appSettings))
        
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .displayEditAddressScreen:
                self.stateMachine.tryEvent(.presentEditAddress)
            case .dismiss:
                navigationStackCoordinator.pop()
            case .displayManageAuthorizedSpacesScreen(let selection):
                self.stateMachine.tryEvent(.presentManageAuthorizedSpacesScreen, userInfo: selection)
            }
        }
        .store(in: &cancellables)
        
        navigationStackCoordinator.push(coordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedSecurityAndPrivacyScreen)
        }
    }
    
    private func presentEditAddressScreen() {
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = EditRoomAddressScreenCoordinator(parameters: .init(roomProxy: roomProxy,
                                                                             clientProxy: flowParameters.userSession.clientProxy,
                                                                             userIndicatorController: flowParameters.userIndicatorController))
        
        coordinator.actionsPublisher.sink { [weak self] action in
            switch action {
            case .dismiss:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedEditAddress)
        }
    }
    
    private func presentManageAuthorizedSpacesScreen(selection: AuthorizedSpacesSelection) {
        let navigationStack = NavigationStackCoordinator()
        let coordinator = ManageAuthorizedSpacesScreenCoordinator(parameters: .init(authorizedSpacesSelection: selection,
                                                                                    mediaProvider: flowParameters.userSession.mediaProvider))
        coordinator.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .dismiss:
                navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        navigationStack.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(navigationStack) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedManageAuthorizedSpacesScreen)
        }
    }
    
    private func presentTransferOwnershipScreen() {
        let parameters = RoomChangeRolesScreenCoordinatorParameters(mode: .owner,
                                                                    roomProxy: roomProxy,
                                                                    mediaProvider: flowParameters.userSession.mediaProvider,
                                                                    userIndicatorController: flowParameters.userIndicatorController,
                                                                    analytics: flowParameters.analytics)
        let stackCoordinator = NavigationStackCoordinator()
        let coordinator = RoomChangeRolesScreenCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            switch action {
            case .complete:
                self?.navigationStackCoordinator.setSheetCoordinator(nil)
            }
        }
        .store(in: &cancellables)
        
        stackCoordinator.setRootCoordinator(coordinator)
        navigationStackCoordinator.setSheetCoordinator(stackCoordinator) { [weak self] in
            self?.stateMachine.tryEvent(.dismissedTransferOwnership)
        }
    }
    
    // MARK: - Other flows
    
    private func startRolesAndPermissionsFlow() {
        let parameters = RoomRolesAndPermissionsFlowCoordinatorParameters(roomProxy: roomProxy,
                                                                          mediaProvider: flowParameters.userSession.mediaProvider,
                                                                          navigationStackCoordinator: navigationStackCoordinator,
                                                                          userIndicatorController: flowParameters.userIndicatorController,
                                                                          analytics: flowParameters.analytics)
        let coordinator = RoomRolesAndPermissionsFlowCoordinator(parameters: parameters)
        coordinator.actionsPublisher.sink { [weak self] action in
            switch action {
            case .complete:
                self?.stateMachine.tryEvent(.stopRolesAndPermissionsFlow)
            }
        }
        .store(in: &cancellables)
        
        childFlowCoordinator = coordinator
        coordinator.start()
    }
    
    private func startMembersListFlow() {
        let flowCoordinator = RoomMembersFlowCoordinator(entryPoint: .roomMembersList,
                                                         roomProxy: roomProxy,
                                                         navigationStackCoordinator: navigationStackCoordinator,
                                                         flowParameters: flowParameters)
        flowCoordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .finished:
                stateMachine.tryEvent(.stopMembersListFlow)
            case .presentCallScreen(let roomProxy):
                actionsSubject.send(.presentCallScreen(roomProxy: roomProxy))
            case .verifyUser(let userID):
                actionsSubject.send(.verifyUser(userID: userID))
            }
        }
        .store(in: &cancellables)
        
        childFlowCoordinator = flowCoordinator
        flowCoordinator.start(animated: true)
    }
}
