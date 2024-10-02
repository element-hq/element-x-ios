//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct StartChatScreenCoordinatorParameters {
    let orientationManager: OrientationManagerProtocol
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let userDiscoveryService: UserDiscoveryServiceProtocol
}

enum StartChatScreenCoordinatorAction {
    case close
    case openRoom(withIdentifier: String)
}

final class StartChatScreenCoordinator: CoordinatorProtocol {
    private let parameters: StartChatScreenCoordinatorParameters
    private var viewModel: StartChatScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<StartChatScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    private var createRoomParameters = CurrentValueSubject<CreateRoomFlowParameters, Never>(.init())
    private var createRoomParametersPublisher: CurrentValuePublisher<CreateRoomFlowParameters, Never> {
        createRoomParameters.asCurrentValuePublisher()
    }
    
    private let selectedUsers = CurrentValueSubject<[UserProfileProxy], Never>([])
    private var selectedUsersPublisher: CurrentValuePublisher<[UserProfileProxy], Never> {
        selectedUsers.asCurrentValuePublisher()
    }
        
    var actions: AnyPublisher<StartChatScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: StartChatScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = StartChatScreenViewModel(userSession: parameters.userSession,
                                             analytics: ServiceLocator.shared.analytics,
                                             userIndicatorController: parameters.userIndicatorController,
                                             userDiscoveryService: parameters.userDiscoveryService)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                actionsSubject.send(.close)
            case .createRoom:
                // before creating a room we select the users we would like to invite in that room
                presentInviteUsersScreen()
            case .openRoom(let identifier):
                actionsSubject.send(.openRoom(withIdentifier: identifier))
            }
        }
        .store(in: &cancellables)
    }
        
    // MARK: - Public
    
    func toPresentable() -> AnyView {
        AnyView(StartChatScreen(context: viewModel.context))
    }
    
    // MARK: - Private
    
    private func presentInviteUsersScreen() {
        let inviteParameters = InviteUsersScreenCoordinatorParameters(clientProxy: parameters.userSession.clientProxy,
                                                                      selectedUsers: selectedUsersPublisher,
                                                                      roomType: .draft,
                                                                      mediaProvider: parameters.userSession.mediaProvider,
                                                                      userDiscoveryService: parameters.userDiscoveryService,
                                                                      userIndicatorController: parameters.userIndicatorController)
        let coordinator = InviteUsersScreenCoordinator(parameters: inviteParameters)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            
            switch action {
            case .cancel:
                break // Not shown in this flow.
            case .proceed:
                openCreateRoomScreen()
            case .invite:
                break
            case .toggleUser(let user):
                toggleUser(user)
            }
        }
        .store(in: &cancellables)
        
        parameters.navigationStackCoordinator?.push(coordinator) { [weak self] in
            self?.createRoomParameters.send(.init())
            self?.selectedUsers.send([])
        }
    }
    
    private func openCreateRoomScreen() {
        let createParameters = CreateRoomCoordinatorParameters(userSession: parameters.userSession,
                                                               userIndicatorController: parameters.userIndicatorController,
                                                               createRoomParameters: createRoomParametersPublisher,
                                                               selectedUsers: selectedUsersPublisher)
        let coordinator = CreateRoomCoordinator(parameters: createParameters)
        coordinator.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .deselectUser(let user):
                self.toggleUser(user)
            case .updateDetails(let details):
                self.createRoomParameters.send(details)
            case .openRoom(let identifier):
                self.actionsSubject.send(.openRoom(withIdentifier: identifier))
            case .displayMediaPickerWithSource(let source):
                self.displayMediaPickerWithSource(source)
            case .removeImage:
                var parameters = self.createRoomParameters.value
                parameters.avatarImageMedia = nil
                self.createRoomParameters.send(parameters)
            }
        }
        .store(in: &cancellables)
        
        parameters.navigationStackCoordinator?.push(coordinator)
    }
    
    // MARK: - Private
    
    let mediaUploadingPreprocessor = MediaUploadingPreprocessor()
    private func displayMediaPickerWithSource(_ source: MediaPickerScreenSource) {
        let stackCoordinator = NavigationStackCoordinator()
        
        let mediaPickerCoordinator = MediaPickerScreenCoordinator(userIndicatorController: parameters.userIndicatorController, source: source, orientationManager: parameters.orientationManager) { [weak self] action in
            guard let self else { return }
            switch action {
            case .cancel:
                parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
            case .selectMediaAtURL(let url):
                processAvatar(from: url)
            }
        }
        
        stackCoordinator.setRootCoordinator(mediaPickerCoordinator)
        
        parameters.navigationStackCoordinator?.setSheetCoordinator(stackCoordinator)
    }
    
    private func processAvatar(from url: URL) {
        parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
        showLoadingIndicator()
        Task { [weak self] in
            guard let self else { return }
            do {
                let media = try await mediaUploadingPreprocessor.processMedia(at: url).get()
                var parameters = createRoomParameters.value
                parameters.avatarImageMedia = media
                createRoomParameters.send(parameters)
            } catch {
                parameters.userIndicatorController.alertInfo = AlertInfo(id: .init(), title: L10n.commonError, message: L10n.errorUnknown)
            }
            hideLoadingIndicator()
        }
    }
    
    private func toggleUser(_ user: UserProfileProxy) {
        var selectedUsers = selectedUsers.value
        if let index = selectedUsers.firstIndex(where: { $0.userID == user.userID }) {
            selectedUsers.remove(at: index)
        } else {
            selectedUsers.append(user)
        }
        self.selectedUsers.send(selectedUsers)
    }
    
    // MARK: Loading indicator
    
    private static let loadingIndicatorIdentifier = "\(StartChatScreenCoordinator.self)-Loading"
    
    private func showLoadingIndicator() {
        parameters.userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                                         type: .modal,
                                                                         title: L10n.commonLoading,
                                                                         persistent: true))
    }
    
    private func hideLoadingIndicator() {
        parameters.userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
