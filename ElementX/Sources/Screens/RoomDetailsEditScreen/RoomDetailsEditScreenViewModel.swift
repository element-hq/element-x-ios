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

typealias RoomDetailsEditScreenViewModelType = StateStoreViewModel<RoomDetailsEditScreenViewState, RoomDetailsEditScreenViewAction>

class RoomDetailsEditScreenViewModel: RoomDetailsEditScreenViewModelType, RoomDetailsEditScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<RoomDetailsEditScreenViewModelAction, Never> = .init()
    private let roomProxy: RoomProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let mediaPreprocessor: MediaUploadingPreprocessor = .init()
    
    var actions: AnyPublisher<RoomDetailsEditScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(accountOwner: RoomMemberProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         roomProxy: RoomProxyProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        self.userIndicatorController = userIndicatorController
        
        let roomAvatar = roomProxy.avatarURL
        let roomName = roomProxy.name
        let roomTopic = roomProxy.topic
        
        super.init(initialViewState: RoomDetailsEditScreenViewState(roomID: roomProxy.id,
                                                                    initialAvatarURL: roomAvatar,
                                                                    initialName: roomName,
                                                                    initialTopic: roomTopic,
                                                                    canEditAvatar: accountOwner.canSendStateEvent(type: .roomAvatar),
                                                                    canEditName: accountOwner.canSendStateEvent(type: .roomName),
                                                                    canEditTopic: accountOwner.canSendStateEvent(type: .roomTopic),
                                                                    avatarURL: roomAvatar,
                                                                    bindings: .init(name: roomName ?? "", topic: roomTopic ?? "")), imageProvider: mediaProvider)
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
            if state.localMedia != nil {
                state.localMedia = nil
            } else {
                state.avatarURL = nil
            }
        }
    }
    
    func didSelectMediaUrl(url: URL) {
        Task {
            let userIndicatorID = UUID().uuidString
            defer {
                userIndicatorController.retractIndicatorWithId(userIndicatorID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID, type: .modal, title: L10n.commonLoading, persistent: true))
            
            let mediaResult = await mediaPreprocessor.processMedia(at: url)
            
            switch mediaResult {
            case .success(.image):
                state.localMedia = try? mediaResult.get()
            case .failure, .success:
                #warning("Show error?")
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
            userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID, type: .modal, title: L10n.screenRoomDetailsUpdatingRoom, persistent: true))
            
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
