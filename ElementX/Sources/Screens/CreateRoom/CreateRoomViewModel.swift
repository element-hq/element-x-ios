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
    private var createRoomParameters: CreateRoomFlowParameters
    private let analytics: AnalyticsService
    private weak var userIndicatorController: UserIndicatorControllerProtocol?
    
    private var actionsSubject: PassthroughSubject<CreateRoomViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<CreateRoomViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         createRoomParameters: CurrentValuePublisher<CreateRoomFlowParameters, Never>,
         selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol?) {
        let parameters = createRoomParameters.value
        
        self.userSession = userSession
        self.createRoomParameters = parameters
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        
        let bindings = CreateRoomViewStateBindings(roomName: parameters.name, roomTopic: parameters.topic, isRoomPrivate: parameters.isRoomPrivate)

        super.init(initialViewState: CreateRoomViewState(selectedUsers: selectedUsers.value, bindings: bindings), imageProvider: userSession.mediaProvider)
        
        createRoomParameters
            .map(\.avatarImageMedia)
            .removeDuplicates { $0?.url == $1?.url }
            .sink { [weak self] mediaInfo in
                self?.createRoomParameters.avatarImageMedia = mediaInfo
                switch mediaInfo {
                case .image(_, let thumbnailURL, _):
                    self?.state.avatarURL = thumbnailURL
                case nil:
                    self?.state.avatarURL = nil
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
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
        case .displayCameraPicker:
            actionsSubject.send(.displayCameraPicker)
        case .displayMediaPicker:
            actionsSubject.send(.displayMediaPicker)
        case .removeImage:
            actionsSubject.send(.removeImage)
        }
    }
    
    // MARK: - Private

    private func setupBindings() {
        context.$viewState
            .map(\.bindings)
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates { old, new in
                old.roomName == new.roomName && old.roomTopic == new.roomTopic && old.isRoomPrivate == new.isRoomPrivate
            }
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
        case .failedUploadingMedia(let matrixError):
            switch matrixError {
            case .fileTooLarge:
                // waiting for proper copy
                state.bindings.alertInfo = AlertInfo(id: .fileTooLarge)
            default:
                state.bindings.alertInfo = AlertInfo(id: .failedUploadingMedia)
            }
        case .mediaFileError:
            state.bindings.alertInfo = AlertInfo(id: .mediaFileError)
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
        
        let avatarURL: URL?
        if let media = createRoomParameters.avatarImageMedia {
            switch await clientProxy.uploadMedia(media) {
            case .success(let url):
                avatarURL = URL(string: url)
            case .failure(let error):
                displayError(error)
                return
            }
        } else {
            avatarURL = nil
        }

        switch await clientProxy.createRoom(name: createRoomParameters.name,
                                            topic: createRoomParameters.topic,
                                            isRoomPrivate: createRoomParameters.isRoomPrivate,
                                            userIDs: state.selectedUsers.map(\.userID),
                                            avatarURL: avatarURL) {
        case .success(let roomId):
            analytics.trackCreatedRoom(isDM: false)
            actionsSubject.send(.openRoom(withIdentifier: roomId))
        case .failure(let failure):
            displayError(failure)
        }
    }
    
    // MARK: Loading indicator
    
    private static let loadingIndicatorIdentifier = "CreateRoomLoading"
    
    private func showLoadingIndicator() {
        userIndicatorController?.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                               type: .modal(progress: .indeterminate, interactiveDismissDisabled: true),
                                                               title: L10n.commonLoading,
                                                               persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController?.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
