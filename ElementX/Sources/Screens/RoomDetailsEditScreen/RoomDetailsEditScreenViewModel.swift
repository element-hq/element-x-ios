//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

typealias RoomDetailsEditScreenViewModelType = StateStoreViewModel<RoomDetailsEditScreenViewState, RoomDetailsEditScreenViewAction>

class RoomDetailsEditScreenViewModel: RoomDetailsEditScreenViewModelType, RoomDetailsEditScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<RoomDetailsEditScreenViewModelAction, Never> = .init()
    private let roomProxy: JoinedRoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let mediaPreprocessor: MediaUploadingPreprocessor = .init()
    
    var actions: AnyPublisher<RoomDetailsEditScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomProxy: JoinedRoomProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        
        let roomAvatar = roomProxy.avatarURL
        let roomName = roomProxy.name
        let roomTopic = roomProxy.topic
        
        super.init(initialViewState: RoomDetailsEditScreenViewState(roomID: roomProxy.id,
                                                                    initialAvatarURL: roomAvatar,
                                                                    initialName: roomName ?? "",
                                                                    initialTopic: roomTopic ?? "",
                                                                    avatarURL: roomAvatar,
                                                                    bindings: .init(name: roomName ?? "", topic: roomTopic ?? "")), mediaProvider: mediaProvider)
        
        Task {
            // Can't use async let because the mocks aren't thread safe when calling the same method 🤦‍♂️
            state.canEditAvatar = await (try? roomProxy.canUser(userID: roomProxy.ownUserID, sendStateEvent: .roomAvatar).get()) == .some(true)
            state.canEditName = await (try? roomProxy.canUser(userID: roomProxy.ownUserID, sendStateEvent: .roomName).get()) == .some(true)
            state.canEditTopic = await (try? roomProxy.canUser(userID: roomProxy.ownUserID, sendStateEvent: .roomTopic).get()) == .some(true)
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: RoomDetailsEditScreenViewAction) {
        switch viewAction {
        case .cancel:
            actionsSubject.send(.cancel)
        case .save:
            saveRoomDetails()
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
            defer {
                userIndicatorController.retractIndicatorWithId(userIndicatorID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID,
                                                                  type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                                  title: L10n.commonLoading,
                                                                  persistent: true))
            
            let mediaResult = await mediaPreprocessor.processMedia(at: url)
            
            switch mediaResult {
            case .success(.image):
                state.localMedia = try? mediaResult.get()
            case .failure, .success:
                userIndicatorController.alertInfo = .init(id: .init())
            }
        }
    }
    
    // MARK: - Private
    
    private func saveRoomDetails() {
        Task {
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
                userIndicatorController.alertInfo = .init(id: .init(),
                                                          title: L10n.screenRoomDetailsEditionErrorTitle,
                                                          message: L10n.screenRoomDetailsEditionError)
            }
        }
    }
}
