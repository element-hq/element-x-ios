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

typealias CreateRoomViewModelType = StateStoreViewModel<CreateRoomViewState, CreateRoomViewAction>

class CreateRoomViewModel: CreateRoomViewModelType, CreateRoomViewModelProtocol {
    private let userSession: UserSessionProtocol
    private var actionsSubject: PassthroughSubject<CreateRoomViewModelAction, Never> = .init()
    private var createRoomParameters: CreateRoomFlowParameters
    private weak var userIndicatorController: UserIndicatorControllerProtocol?
    
    var actions: AnyPublisher<CreateRoomViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         userIndicatorController: UserIndicatorControllerProtocol?,
         createRoomParameters: CurrentValuePublisher<CreateRoomFlowParameters, Never>,
         selectedUsers: CurrentValuePublisher<[UserProfile], Never>) {
        let parameters = createRoomParameters.value
        self.userSession = userSession
        self.userIndicatorController = userIndicatorController
        self.createRoomParameters = parameters
        let bindings = CreateRoomViewStateBindings(roomName: parameters.name, roomTopic: parameters.topic, isRoomPrivate: parameters.isRoomPrivate)

        super.init(initialViewState: CreateRoomViewState(selectedUsers: selectedUsers.value, bindings: bindings), imageProvider: userSession.mediaProvider)
        
        selectedUsers
            .sink { [weak self] users in
                self?.state.selectedUsers = users
            }
            .store(in: &cancellables)
        
        setupBindings()
    }
    
    // MARK: - Public
    
    override func process(viewAction: CreateRoomViewAction) {
        switch viewAction {
        case .createRoom:
            Task {
                await createRoom()
            }
        case .deselectUser(let user):
            actionsSubject.send(.deselectUser(user))
        }
    }
    
    // MARK: - Private

    private func setupBindings() {
        context.$viewState
            .map(\.bindings)
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .sink { [weak self] bindings in
                guard let self else { return }
                createRoomParameters.name = bindings.roomName
                createRoomParameters.topic = bindings.roomTopic
                createRoomParameters.isRoomPrivate = bindings.isRoomPrivate
                actionsSubject.send(.updateDetails(createRoomParameters))
            }
            .store(in: &cancellables)
    }
    
    private func displayError(_ type: ClientProxyError) {
        switch type {
        case .failedCreatingRoom:
            state.bindings.alertInfo = AlertInfo(id: .failedCreatingRoom,
                                                 title: L10n.commonError,
                                                 message: L10n.screenStartChatErrorStartingChat)
        case .failedSearchingUsers:
            state.bindings.alertInfo = AlertInfo(id: .unknown)
        default:
            break
        }
    }
    
    private var clientProxy: ClientProxyProtocol {
        userSession.clientProxy
    }
    
    private func createRoom() async {
        defer {
            hideLoadingIndicator()
        }
        showLoadingIndicator()
        switch await clientProxy.createRoom(with: createRoomParameters, userIDs: state.selectedUsers.map(\.userID)) {
        case .success(let roomId):
            actionsSubject.send(.openRoom(withIdentifier: roomId))
        case .failure(let failure):
            displayError(failure)
        }
    }
    
    // MARK: Loading indicator
    
    private static let loadingIndicatorIdentifier = "CreateRoomLoading"
    
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
