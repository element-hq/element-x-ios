//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias CreateRoomViewModelType = StateStoreViewModel<CreateRoomViewState, CreateRoomViewAction>

class CreateRoomViewModel: CreateRoomViewModelType, CreateRoomViewModelProtocol {
    private let userSession: UserSessionProtocol
    private var createRoomParameters: CreateRoomFlowParameters
    private let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    private let analytics: AnalyticsService
    private let userIndicatorController: UserIndicatorControllerProtocol
    private var syncNameAndAlias = true
    @CancellableTask private var checkAliasAvailabilityTask: Task<Void, Never>?
    
    private var actionsSubject: PassthroughSubject<CreateRoomViewModelAction, Never> = .init()
    
    var actions: AnyPublisher<CreateRoomViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         initialParameters: CreateRoomFlowParameters = .init(),
         analytics: AnalyticsService,
         userIndicatorController: UserIndicatorControllerProtocol,
         appSettings: AppSettings) {
        self.userSession = userSession
        createRoomParameters = initialParameters
        mediaUploadingPreprocessor = MediaUploadingPreprocessor(appSettings: appSettings)
        self.analytics = analytics
        self.userIndicatorController = userIndicatorController
        
        let bindings = CreateRoomViewStateBindings(roomTopic: createRoomParameters.topic,
                                                   isRoomPrivate: createRoomParameters.isRoomPrivate,
                                                   isKnockingOnly: appSettings.knockingEnabled ? createRoomParameters.isKnockingOnly : false)

        super.init(initialViewState: CreateRoomViewState(roomName: createRoomParameters.name,
                                                         serverName: userSession.clientProxy.userIDServerName ?? "",
                                                         isKnockingFeatureEnabled: appSettings.knockingEnabled,
                                                         aliasLocalPart: createRoomParameters.aliasLocalPart ?? roomAliasNameFromRoomDisplayName(roomName: createRoomParameters.name),
                                                         bindings: bindings),
                   mediaProvider: userSession.mediaProvider)
        
        setupBindings()
    }
    
    // MARK: - Public
    
    override func process(viewAction: CreateRoomViewAction) {
        switch viewAction {
        case .createRoom:
            Task { await createRoom() }
        case .displayCameraPicker:
            actionsSubject.send(.displayCameraPicker)
        case .displayMediaPicker:
            actionsSubject.send(.displayMediaPicker)
        case .removeImage:
            createRoomParameters.avatarImageMedia = nil
            state.avatarURL = nil
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
    
    func updateAvatar(fileURL: URL) {
        showLoadingIndicator()
        Task { [weak self] in
            guard let self else { return }
            do {
                guard case let .success(maxUploadSize) = await userSession.clientProxy.maxMediaUploadSize else {
                    MXLog.error("Failed to get max upload size")
                    userIndicatorController.alertInfo = AlertInfo(id: .init())
                    return
                }
                let mediaInfo = try await mediaUploadingPreprocessor.processMedia(at: fileURL, maxUploadSize: maxUploadSize).get()
                
                switch mediaInfo {
                case .image(_, let thumbnailURL, _):
                    createRoomParameters.avatarImageMedia = mediaInfo
                    state.avatarURL = thumbnailURL
                default:
                    break
                }
            } catch {
                userIndicatorController.alertInfo = AlertInfo(id: .init())
            }
            hideLoadingIndicator()
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
                      let canonicalAlias = String.makeCanonicalAlias(aliasLocalPart: aliasLocalPart,
                                                                     serverName: state.serverName) else {
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
            guard let canonicalAlias = String.makeCanonicalAlias(aliasLocalPart: createRoomParameters.aliasLocalPart,
                                                                 serverName: state.serverName),
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
                case .failedUploadingMedia(let errorKind):
                    switch errorKind {
                    case .tooLarge:
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
                                                        topic: createRoomParameters.topic.isBlank ? nil : createRoomParameters.topic,
                                                        isRoomPrivate: createRoomParameters.isRoomPrivate,
                                                        // As of right now we don't want to make private rooms with the knock rule
                                                        isKnockingOnly: createRoomParameters.isRoomPrivate ? false : createRoomParameters.isKnockingOnly,
                                                        userIDs: [], // The invite users screen is shown next so we don't need to invite anyone right now.
                                                        avatarURL: avatarURL,
                                                        aliasLocalPart: createRoomParameters.isRoomPrivate ? nil : createRoomParameters.aliasLocalPart) {
        case .success(let roomID):
            guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
                state.bindings.alertInfo = AlertInfo(id: .failedCreatingRoom,
                                                     title: L10n.commonError,
                                                     message: L10n.screenStartChatErrorStartingChat)
                return
            }
            analytics.trackCreatedRoom(isDM: false)
            actionsSubject.send(.createdRoom(roomProxy))
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
