//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias CreateRoomViewModelType = StateStoreViewModel<CreateRoomViewState, CreateRoomViewAction>

class CreateRoomViewModel: CreateRoomViewModelType, CreateRoomViewModelProtocol {
    private let userSession: UserSessionProtocol
    private var createRoomParameters: CreateRoomFlowParameters
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<CreateRoomViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<CreateRoomViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         createRoomParameters: CurrentValuePublisher<CreateRoomFlowParameters, Never>,
         selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol) {
        let parameters = createRoomParameters.value
        
        self.userSession = userSession
        self.createRoomParameters = parameters
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        
        let bindings = CreateRoomViewStateBindings(roomName: parameters.name, roomTopic: parameters.topic, isRoomPrivate: parameters.isRoomPrivate)

        super.init(initialViewState: CreateRoomViewState(selectedUsers: selectedUsers.value, bindings: bindings), mediaProvider: userSession.mediaProvider)
        
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
    
    private func createRoom() async {
        defer {
            hideLoadingIndicator()
        }
        showLoadingIndicator()
        
        let avatarURL: URL?
        if let media = createRoomParameters.avatarImageMedia {
            switch await userSession.clientProxy.uploadMedia(media) {
            case .success(let url):
                avatarURL = URL(string: url)
            case .failure(let error):
                switch error {
                case .failedUploadingMedia(_, let errorCode):
                    switch errorCode {
                    case .fileTooLarge:
                        state.bindings.alertInfo = AlertInfo(id: .fileTooLarge)
                    default:
                        state.bindings.alertInfo = AlertInfo(id: .failedUploadingMedia)
                    }
                case .invalidMedia:
                    state.bindings.alertInfo = AlertInfo(id: .mediaFileError)
                default:
                    state.bindings.alertInfo = AlertInfo(id: .unknown)
                }
                
                return
            }
        } else {
            avatarURL = nil
        }
        
        switch await userSession.clientProxy.createRoom(name: createRoomParameters.name,
                                                        topic: createRoomParameters.topic,
                                                        isRoomPrivate: createRoomParameters.isRoomPrivate,
                                                        userIDs: state.selectedUsers.map(\.userID),
                                                        avatarURL: avatarURL) {
        case .success(let roomId):
            analytics.trackCreatedRoom(isDM: false)
            actionsSubject.send(.openRoom(withIdentifier: roomId))
        case .failure:
            state.bindings.alertInfo = AlertInfo(id: .failedCreatingRoom,
                                                 title: L10n.commonError,
                                                 message: L10n.screenStartChatErrorStartingChat)
        }
    }
    
    // MARK: Loading indicator
    
    private static let loadingIndicatorIdentifier = "\(CreateRoomViewModel.self)-Loading"
    
    private func showLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonLoading,
                                                              persistent: true))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
