//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomDetailsEditScreenViewModelType = StateStoreViewModel<RoomDetailsEditScreenViewState, RoomDetailsEditScreenViewAction>

class RoomDetailsEditScreenViewModel: RoomDetailsEditScreenViewModelType, RoomDetailsEditScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<RoomDetailsEditScreenViewModelAction, Never> = .init()
    private let roomProxy: JoinedRoomProxyProtocol
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    
    var actions: AnyPublisher<RoomDetailsEditScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomProxy: JoinedRoomProxyProtocol,
         userSession: UserSessionProtocol,
         mediaUploadingPreprocessor: MediaUploadingPreprocessor,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        clientProxy = userSession.clientProxy
        self.mediaUploadingPreprocessor = mediaUploadingPreprocessor
        self.userIndicatorController = userIndicatorController
        
        let roomAvatar = roomProxy.infoPublisher.value.avatarURL
        let roomName = roomProxy.infoPublisher.value.displayName
        let roomTopic = roomProxy.infoPublisher.value.topic
        let isSpace = roomProxy.infoPublisher.value.isSpace
        
        super.init(initialViewState: RoomDetailsEditScreenViewState(roomID: roomProxy.id,
                                                                    isSpace: isSpace,
                                                                    initialAvatarURL: roomAvatar,
                                                                    initialName: roomName ?? "",
                                                                    initialTopic: roomTopic ?? "",
                                                                    avatarURL: roomAvatar,
                                                                    bindings: .init(name: roomName ?? "", topic: roomTopic ?? "")),
                   mediaProvider: userSession.mediaProvider)
        
        roomProxy.infoPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] roomInfo in
                self?.updateRoomInfo(roomInfo: roomInfo)
            }
            .store(in: &cancellables)
        
        updateRoomInfo(roomInfo: roomProxy.infoPublisher.value)
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomDetailsEditScreenViewAction) {
        switch viewAction {
        case .cancel:
            cancel()
        case .save:
            Task { await saveRoomDetails() }
        case .presentMediaSource:
            state.bindings.showMediaSheet = true
        case .displayCameraPicker:
            actionsSubject.send(.displayCameraPicker)
        case .displayMediaPicker:
            actionsSubject.send(.displayMediaPicker)
        case .removeImage:
            state.avatarURL = nil
            state.localMedia = nil
        }
    }
    
    func didSelectMediaUrl(url: URL) {
        Task {
            let userIndicatorID = UUID().uuidString
            defer { userIndicatorController.retractIndicatorWithId(userIndicatorID) }
            userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID,
                                                                  type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                                  title: L10n.commonLoading,
                                                                  persistent: true))
            
            guard case let .success(maxUploadSize) = await clientProxy.maxMediaUploadSize else {
                MXLog.error("Failed to get max upload size")
                state.bindings.alertInfo = .init(id: .unknown)
                return
            }
            let mediaResult = await mediaUploadingPreprocessor.processMedia(at: url, maxUploadSize: maxUploadSize)
            
            switch mediaResult {
            case .success(.image):
                state.localMedia = try? mediaResult.get()
            case .failure, .success:
                state.bindings.alertInfo = .init(id: .failedProcessingMedia)
            }
        }
    }
    
    // MARK: - Private
    
    private func updateRoomInfo(roomInfo: RoomInfoProxyProtocol) {
        if let powerLevels = roomInfo.powerLevels {
            state.canEditAvatar = powerLevels.canOwnUser(sendStateEvent: .roomAvatar)
            state.canEditName = powerLevels.canOwnUser(sendStateEvent: .roomName)
            state.canEditTopic = powerLevels.canOwnUser(sendStateEvent: .roomTopic)
        }
    }
    
    private func cancel() {
        if state.canSave {
            state.bindings.alertInfo = .init(id: .unsavedChanges,
                                             title: L10n.dialogUnsavedChangesTitle,
                                             message: L10n.dialogUnsavedChangesDescription,
                                             primaryButton: .init(title: L10n.actionSave) { Task { await self.saveRoomDetails() } },
                                             secondaryButton: .init(title: L10n.actionDiscard, role: .cancel) { self.actionsSubject.send(.cancel) })
        } else {
            actionsSubject.send(.cancel)
        }
    }
    
    private func saveRoomDetails() async {
        let userIndicatorID = UUID().uuidString
        defer {
            userIndicatorController.retractIndicatorWithId(userIndicatorID)
        }
        userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.screenRoomDetailsUpdatingRoom,
                                                              persistent: true))
        
        do {
            try await withThrowingTaskGroup(of: Void.self) { group in
                if state.avatarDidChange {
                    group.addTask {
                        if let localMedia = await self.state.localMedia {
                            try await self.roomProxy.uploadAvatar(media: localMedia).get()
                        } else if await self.state.avatarURL == nil {
                            try await self.roomProxy.removeAvatar().get()
                        }
                    }
                }
                
                if state.nameDidChange {
                    group.addTask {
                        try await self.roomProxy.setName(self.state.bindings.name).get()
                    }
                }
                
                if state.topicDidChange {
                    group.addTask {
                        try await self.roomProxy.setTopic(self.state.bindings.topic).get()
                    }
                }
                
                try await group.waitForAll()
            }
            
            actionsSubject.send(.saveFinished)
        } catch {
            state.bindings.alertInfo = .init(id: .saveError,
                                             title: L10n.screenRoomDetailsEditionErrorTitle,
                                             message: L10n.screenRoomDetailsEditionError)
        }
    }
}
