//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
                                                                    bindings: .init()), mediaProvider: mediaProvider)
        
        clientProxy.userAvatarURLPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.currentAvatarURL, on: self)
            .store(in: &cancellables)
        
        clientProxy.userAvatarURLPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.selectedAvatarURL, on: self)
            .store(in: &cancellables)
        
        clientProxy.userDisplayNamePublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.currentDisplayName, on: self)
            .store(in: &cancellables)
        
        clientProxy.userDisplayNamePublisher
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
