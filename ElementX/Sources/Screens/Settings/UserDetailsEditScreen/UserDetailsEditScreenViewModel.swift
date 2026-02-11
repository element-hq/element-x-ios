//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias UserDetailsEditScreenViewModelType = StateStoreViewModelV2<UserDetailsEditScreenViewState, UserDetailsEditScreenViewAction>

class UserDetailsEditScreenViewModel: UserDetailsEditScreenViewModelType, UserDetailsEditScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<UserDetailsEditScreenViewModelAction, Never> = .init()
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let mediaUploadingPreprocessor: MediaUploadingPreprocessor
    
    var actions: AnyPublisher<UserDetailsEditScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userSession: UserSessionProtocol,
         mediaUploadingPreprocessor: MediaUploadingPreprocessor,
         userIndicatorController: UserIndicatorControllerProtocol) {
        clientProxy = userSession.clientProxy
        self.mediaUploadingPreprocessor = mediaUploadingPreprocessor
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: UserDetailsEditScreenViewState(userID: clientProxy.userID,
                                                                    bindings: .init()), mediaProvider: userSession.mediaProvider)
        
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
        case .cancel:
            showUnsavedChangesAlert() // The cancel button is only shown when there are unsaved changes.
        case .save:
            Task { await saveUserDetails() }
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
    
    private func showUnsavedChangesAlert() {
        state.bindings.alertInfo = .init(id: .unsavedChanges,
                                         title: L10n.dialogUnsavedChangesTitle,
                                         message: L10n.dialogUnsavedChangesDescription,
                                         primaryButton: .init(title: L10n.actionSave) { Task { await self.saveUserDetails() } },
                                         secondaryButton: .init(title: L10n.actionDiscard, role: .cancel) { self.actionsSubject.send(.dismiss) })
    }
    
    private func saveUserDetails() async {
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
            
            actionsSubject.send(.dismiss)
        } catch {
            state.bindings.alertInfo = .init(id: .saveError,
                                             title: L10n.screenEditProfileErrorTitle,
                                             message: L10n.screenEditProfileError)
        }
    }
}
