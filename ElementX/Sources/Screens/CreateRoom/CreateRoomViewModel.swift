//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias CreateRoomViewModelType = StateStoreViewModel<CreateRoomViewState, CreateRoomViewAction>

class CreateRoomViewModel: CreateRoomViewModelType, CreateRoomViewModelProtocol {
    private let userSession: UserSessionProtocol
    private var createRoomParameters: CreateRoomFlowParameters
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    private var syncNameAndAlias = true
    @CancellableTask private var checkAliasAvailabilityTask: Task<Void, Never>?
    
    private var actionsSubject: PassthroughSubject<CreateRoomViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<CreateRoomViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         createRoomParameters: CurrentValuePublisher<CreateRoomFlowParameters, Never>,
         selectedUsers: CurrentValuePublisher<[UserProfileProxy], Never>,
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol,
         appSettings: AppSettings) {
        let parameters = createRoomParameters.value
        
        self.userSession = userSession
        self.createRoomParameters = parameters
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        
        let bindings = CreateRoomViewStateBindings(roomTopic: parameters.topic,
                                                   isRoomPrivate: parameters.isRoomPrivate,
                                                   isKnockingOnly: appSettings.knockingEnabled ? parameters.isKnockingOnly : false)

        super.init(initialViewState: CreateRoomViewState(roomName: parameters.name,
                                                         serverName: userSession.clientProxy.userIDServerName ?? "",
                                                         isKnockingFeatureEnabled: appSettings.knockingEnabled,
                                                         selectedUsers: selectedUsers.value,
                                                         aliasLocalPart: parameters.aliasLocalPart ?? roomAliasNameFromRoomDisplayName(roomName: parameters.name),
                                                         bindings: bindings),
                   mediaProvider: userSession.mediaProvider)
        
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
        case .updateAliasLocalPart(let aliasLocalPart):
            state.aliasLocalPart = aliasLocalPart.lowercased()
            // If this has been called this means that the user wants a custom address not necessarily reflecting the name
            // So we disable the two from syncing.
            syncNameAndAlias = false
        case .updateRoomName(let name):
            // Reset the syncing if the name is fully cancelled
            if name.isEmpty {
                syncNameAndAlias = true
            }
            state.roomName = name
            if syncNameAndAlias {
                state.aliasLocalPart = roomAliasNameFromRoomDisplayName(roomName: name)
            }
        }
    }
    
    // MARK: - Private

    private func setupBindings() {
        // Reset the state related to public rooms if the user choses the room to be empty
        context.$viewState
            .dropFirst()
            .map(\.bindings.isRoomPrivate)
            .removeDuplicates()
            .filter { $0 }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] _ in
                guard let self else { return }
                state.bindings.isKnockingOnly = false
                state.aliasErrors = []
                state.aliasLocalPart = roomAliasNameFromRoomDisplayName(roomName: state.roomName)
                syncNameAndAlias = true
            }
            .store(in: &cancellables)
        
        context.$viewState
            .throttle(for: 0.5, scheduler: DispatchQueue.main, latest: true)
            .removeDuplicates { old, new in
                old.roomName == new.roomName &&
                    old.bindings.roomTopic == new.bindings.roomTopic &&
                    old.bindings.isRoomPrivate == new.bindings.isRoomPrivate &&
                    old.bindings.isKnockingOnly == new.bindings.isKnockingOnly &&
                    old.aliasLocalPart == new.aliasLocalPart
            }
            .sink { [weak self] state in
                guard let self else { return }
                updateParameters(state: state)
                actionsSubject.send(.updateDetails(createRoomParameters))
            }
            .store(in: &cancellables)
        
        context.$viewState
            .map(\.aliasLocalPart)
            .removeDuplicates()
            .debounce(for: 1, scheduler: DispatchQueue.main)
            .sink { [weak self] aliasLocalPart in
                guard let self else {
                    return
                }
                
                guard state.isKnockingFeatureEnabled,
                      !state.bindings.isRoomPrivate,
                      let canonicalAlias = canonicalAlias(aliasLocalPart: aliasLocalPart) else {
                    // While is empty or private room we don't change or display the error
                    return
                }
                
                if !isRoomAliasFormatValid(alias: canonicalAlias) {
                    state.aliasErrors.insert(.invalidSymbols)
                    // If the alias is invalid we don't need to check for availability
                    state.aliasErrors.remove(.alreadyExists)
                    checkAliasAvailabilityTask = nil
                    return
                }
                
                state.aliasErrors.remove(.invalidSymbols)
                
                checkAliasAvailabilityTask = Task { [weak self] in
                    guard let self else {
                        return
                    }
                    
                    if case .success(false) = await self.userSession.clientProxy.isAliasAvailable(canonicalAlias) {
                        guard !Task.isCancelled else { return }
                        state.aliasErrors.insert(.alreadyExists)
                    } else {
                        guard !Task.isCancelled else { return }
                        state.aliasErrors.remove(.alreadyExists)
                    }
                }
            }
            .store(in: &cancellables)
    }
    
    private func updateParameters(state: CreateRoomViewState) {
        createRoomParameters.name = state.roomName
        createRoomParameters.topic = state.bindings.roomTopic
        createRoomParameters.isRoomPrivate = state.bindings.isRoomPrivate
        createRoomParameters.isKnockingOnly = state.bindings.isKnockingOnly
        if state.isKnockingFeatureEnabled, !state.aliasLocalPart.isEmpty {
            createRoomParameters.aliasLocalPart = state.aliasLocalPart
        } else {
            createRoomParameters.aliasLocalPart = nil
        }
    }
    
    private func createRoom() async {
        defer {
            hideLoadingIndicator()
        }
        showLoadingIndicator()
        
        // Since the parameters are throttled, we need to make sure that the latest values are used
        updateParameters(state: state)
        
        // Better to double check the errors also when trying to create the room
        if state.isKnockingFeatureEnabled, !createRoomParameters.isRoomPrivate {
            guard let canonicalAlias = canonicalAlias(aliasLocalPart: createRoomParameters.aliasLocalPart),
                  isRoomAliasFormatValid(alias: canonicalAlias) else {
                state.aliasErrors = [.invalidSymbols]
                return
            }
            
            switch await userSession.clientProxy.isAliasAvailable(canonicalAlias) {
            case .success(true):
                break
            case .success(false):
                state.aliasErrors = [.alreadyExists]
                return
            case .failure:
                state.bindings.alertInfo = AlertInfo(id: .unknown)
                return
            }
        }
        
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
                                                        // As of right now we don't want to make private rooms with the knock rule
                                                        isKnockingOnly: createRoomParameters.isRoomPrivate ? false : createRoomParameters.isKnockingOnly,
                                                        userIDs: state.selectedUsers.map(\.userID),
                                                        avatarURL: avatarURL,
                                                        aliasLocalPart: createRoomParameters.isRoomPrivate ? nil : createRoomParameters.aliasLocalPart) {
        case .success(let roomId):
            analytics.trackCreatedRoom(isDM: false)
            actionsSubject.send(.openRoom(withIdentifier: roomId))
        case .failure:
            state.bindings.alertInfo = AlertInfo(id: .failedCreatingRoom,
                                                 title: L10n.commonError,
                                                 message: L10n.screenStartChatErrorStartingChat)
        }
    }
    
    func canonicalAlias(aliasLocalPart: String?) -> String? {
        guard let aliasLocalPart,
              !aliasLocalPart.isEmpty else {
            return nil
        }
        return "#\(aliasLocalPart):\(state.serverName)"
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
