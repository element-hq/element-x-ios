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

struct StartChatScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    weak var userIndicatorController: UserIndicatorControllerProtocol?
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
    private var cancellables: Set<AnyCancellable> = .init()
    
    private var createRoomParameters = CurrentValueSubject<CreateRoomFlowParameters, Never>(.init())
    private var createRoomParametersPublisher: CurrentValuePublisher<CreateRoomFlowParameters, Never> {
        createRoomParameters.asCurrentValuePublisher()
    }
    
    private let selectedUsers = CurrentValueSubject<[UserProfileProxy], Never>([])
    private var selectedUsersPublisher: CurrentValuePublisher<[UserProfileProxy], Never> {
        selectedUsers.asCurrentValuePublisher()
    }
    
    private var navigationStackCoordinator: NavigationStackCoordinator? {
        parameters.navigationStackCoordinator
    }
    
    private var userIndicatorController: UserIndicatorControllerProtocol? {
        parameters.userIndicatorController
    }
    
    var actions: AnyPublisher<StartChatScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: StartChatScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = StartChatScreenViewModel(userSession: parameters.userSession,
                                             appSettings: ServiceLocator.shared.settings,
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
        let inviteParameters = InviteUsersScreenCoordinatorParameters(selectedUsers: selectedUsersPublisher,
                                                                      roomType: .draft,
                                                                      mediaProvider: parameters.userSession.mediaProvider,
                                                                      userDiscoveryService: parameters.userDiscoveryService)
        let coordinator = InviteUsersScreenCoordinator(parameters: inviteParameters)
        coordinator.actions.sink { [weak self] result in
            guard let self else { return }
            
            switch result {
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
        
        navigationStackCoordinator?.push(coordinator) { [weak self] in
            self?.createRoomParameters.send(.init())
            self?.selectedUsers.send([])
        }
    }
    
    private func openCreateRoomScreen() {
        let createParameters = CreateRoomCoordinatorParameters(userSession: parameters.userSession,
                                                               userIndicatorController: userIndicatorController,
                                                               createRoomParameters: createRoomParametersPublisher,
                                                               selectedUsers: selectedUsersPublisher)
        let coordinator = CreateRoomCoordinator(parameters: createParameters)
        coordinator.actions.sink { [weak self] result in
            guard let self else { return }
            switch result {
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
        
        navigationStackCoordinator?.push(coordinator)
    }
    
    // MARK: - Private
    
    let mediaUploadingPreprocessor = MediaUploadingPreprocessor()
    private func displayMediaPickerWithSource(_ source: MediaPickerScreenSource) {
        let stackCoordinator = NavigationStackCoordinator()
        let userIndicatorController = UserIndicatorController(rootCoordinator: stackCoordinator)
        
        let mediaPickerCoordinator = MediaPickerScreenCoordinator(userIndicatorController: userIndicatorController, source: source) { [weak self] action in
            guard let self else { return }
            switch action {
            case .cancel:
                navigationStackCoordinator?.setSheetCoordinator(nil)
            case .selectMediaAtURL(let url):
                processAvatar(from: url)
            }
        }
        
        stackCoordinator.setRootCoordinator(mediaPickerCoordinator)
        
        navigationStackCoordinator?.setSheetCoordinator(userIndicatorController)
    }
    
    private func processAvatar(from url: URL) {
        navigationStackCoordinator?.setSheetCoordinator(nil)
        showLoadingIndicator()
        Task { [weak self] in
            guard let self else { return }
            do {
                let media = try await mediaUploadingPreprocessor.processMedia(at: url).get()
                var parameters = createRoomParameters.value
                parameters.avatarImageMedia = media
                createRoomParameters.send(parameters)
            } catch {
                userIndicatorController?.alertInfo = AlertInfo(id: .init(), title: L10n.commonError, message: L10n.errorUnknown)
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
    
    private static let loadingIndicatorIdentifier = "StartChatCoordinatorLoading"
    
    private func showLoadingIndicator() {
        userIndicatorController?.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                               type: .modal,
                                                               title: L10n.commonLoading,
                                                               persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController?.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
