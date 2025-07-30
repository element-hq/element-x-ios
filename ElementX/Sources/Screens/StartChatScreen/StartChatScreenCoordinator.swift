//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct StartChatScreenCoordinatorParameters {
    let orientationManager: OrientationManagerProtocol
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
    weak var navigationStackCoordinator: NavigationStackCoordinator?
    let userDiscoveryService: UserDiscoveryServiceProtocol
    let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    let appSettings: AppSettings
}

enum StartChatScreenCoordinatorAction {
    case close
    case openRoom(withIdentifier: String)
    case openRoomDirectorySearch
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
                                             userDiscoveryService: parameters.userDiscoveryService,
                                             appSettings: ServiceLocator.shared.settings)
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
            case .showRoom(let identifier):
                actionsSubject.send(.openRoom(withIdentifier: identifier))
            case .openRoomDirectorySearch:
                actionsSubject.send(.openRoomDirectorySearch)
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
            case .displayMediaPickerWithMode(let mode):
                self.displayMediaPickerWithMode(mode)
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
    
    private func displayMediaPickerWithMode(_ mode: MediaPickerScreenMode) {
        let stackCoordinator = NavigationStackCoordinator()
        
        let mediaPickerCoordinator = MediaPickerScreenCoordinator(mode: mode,
                                                                  appSettings: parameters.appSettings,
                                                                  userIndicatorController: parameters.userIndicatorController,
                                                                  orientationManager: parameters.orientationManager) { [weak self] action in
            guard let self else { return }
            switch action {
            case .cancel:
                parameters.navigationStackCoordinator?.setSheetCoordinator(nil)
            case .selectedMediaAtURLs(let urls):
                guard urls.count == 1,
                      let url = urls.first else {
                    fatalError("Received an invalid number of URLs")
                }
                
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
                guard case let .success(maxUploadSize) = await parameters.userSession.clientProxy.maxMediaUploadSize else {
                    MXLog.error("Failed to get max upload size")
                    parameters.userIndicatorController.alertInfo = AlertInfo(id: .init())
                    return
                }
                let media = try await parameters.mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize).get()
                var parameters = createRoomParameters.value
                parameters.avatarImageMedia = media
                createRoomParameters.send(parameters)
            } catch {
                parameters.userIndicatorController.alertInfo = AlertInfo(id: .init())
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
