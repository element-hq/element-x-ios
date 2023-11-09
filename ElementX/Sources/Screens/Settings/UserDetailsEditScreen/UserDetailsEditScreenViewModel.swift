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

typealias UserDetailsEditScreenViewModelType = StateStoreViewModel<UserDetailsEditScreenViewState, UserDetailsEditScreenViewAction>

class UserDetailsEditScreenViewModel: UserDetailsEditScreenViewModelType, UserDetailsEditScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<UserDetailsEditScreenViewModelAction, Never> = .init()
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let mediaPreprocessor: MediaUploadingPreprocessor = .init()
    
    var actions: AnyPublisher<UserDetailsEditScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: UserDetailsEditScreenViewState(userID: clientProxy.userID,
                                                                    bindings: .init()), imageProvider: mediaProvider)
        
        clientProxy.userAvatarURL
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.currentAvatarURL, on: self)
            .store(in: &cancellables)
        
        clientProxy.userAvatarURL
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.selectedAvatarURL, on: self)
            .store(in: &cancellables)
        
        clientProxy.userDisplayName
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.currentDisplayName, on: self)
            .store(in: &cancellables)
        
        clientProxy.userDisplayName
            .receive(on: DispatchQueue.main)
            .sink { [weak self] displayName in
                guard let self else { return }
                
                state.bindings.name = displayName ?? ""
            }
            .store(in: &cancellables)
        
        Task {
            await self.clientProxy.loadUserAvatarURL()
            await self.clientProxy.loadUserDisplayName()
        }
    }
    
    // MARK: - Public
    
    override func process(viewAction: UserDetailsEditScreenViewAction) {
        switch viewAction {
        case .save:
            saveUserDetails()
        case .presentMediaSource:
            state.bindings.showMediaSheet = true
        case .displayCameraPicker:
            actionsSubject.send(.displayCameraPicker)
        case .displayMediaPicker:
            actionsSubject.send(.displayMediaPicker)
        case .removeImage:
            state.localMedia = nil
            state.selectedAvatarURL = nil
        }
    }
    
    func didSelectMediaURL(url: URL) {
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
                userIndicatorController.alertInfo = .init(id: .init(), title: L10n.commonError, message: L10n.errorUnknown)
            }
        }
    }
    
    // MARK: - Private
    
    private func saveUserDetails() {
        Task {
            let userIndicatorID = UUID().uuidString
            defer {
                userIndicatorController.retractIndicatorWithId(userIndicatorID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID,
                                                                  type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                                  title: L10n.screenEditProfileUpdatingDetails,
                                                                  persistent: true))
            
            do {
                try await withThrowingTaskGroup(of: Void.self) { group in
                    if state.avatarDidChange {
                        group.addTask {
                            if let localMedia = await self.state.localMedia {
                                try await self.clientProxy.setUserAvatar(media: localMedia).get()
                            } else if await self.state.selectedAvatarURL == nil {
                                try await self.clientProxy.removeUserAvatar().get()
                            }
                        }
                    }
                    
                    if state.nameDidChange {
                        group.addTask {
                            try await self.clientProxy.setUserDisplayName(self.state.bindings.name).get()
                        }
                    }
                    
                    try await group.waitForAll()
                }
            } catch {
                userIndicatorController.alertInfo = .init(id: .init(),
                                                          title: L10n.screenEditProfileErrorTitle,
                                                          message: L10n.screenEditProfileError)
            }
        }
    }
}
