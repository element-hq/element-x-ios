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

typealias RoomMemberDetailsScreenViewModelType = StateStoreViewModel<RoomMemberDetailsScreenViewState, RoomMemberDetailsScreenViewAction>

class RoomMemberDetailsScreenViewModel: RoomMemberDetailsScreenViewModelType, RoomMemberDetailsScreenViewModelProtocol {
    private let roomProxy: RoomProxyProtocol
    private let userID: String
    private let mediaProvider: MediaProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<RoomMemberDetailsScreenViewModelAction, Never> = .init()
    
    private var roomMemberProxy: RoomMemberProxyProtocol?
    
    var actions: AnyPublisher<RoomMemberDetailsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(roomProxy: RoomProxyProtocol,
         userID: String,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.roomProxy = roomProxy
        self.userID = userID
        self.mediaProvider = mediaProvider
        self.userIndicatorController = userIndicatorController
        
        let initialViewState = RoomMemberDetailsScreenViewState(userID: userID, bindings: .init())
        
        super.init(initialViewState: initialViewState, imageProvider: mediaProvider)
        
        showMemberLoadingIndicator()
        Task {
            defer {
                hideMemberLoadingIndicator()
            }
            
            switch await roomProxy.getMember(userID: userID) {
            case .success(let member):
                roomMemberProxy = member
                state.memberDetails = RoomMemberDetails(withProxy: member)
            case .failure(let error):
                state.bindings.alertInfo = .init(id: .unknown)
                MXLog.error("[RoomFlowCoordinator] Failed to get member: \(error)")
            }
        }
    }
    
    // MARK: - Public
    
    func stop() {
        // Work around QLPreviewController dismissal issues, see the InteractiveQuickLookModifier.
        state.bindings.mediaPreviewItem = nil
        
        hideMemberLoadingIndicator()
    }
    
    override func process(viewAction: RoomMemberDetailsScreenViewAction) {
        switch viewAction {
        case .showUnignoreAlert:
            state.bindings.ignoreUserAlert = .init(action: .unignore)
        case .showIgnoreAlert:
            state.bindings.ignoreUserAlert = .init(action: .ignore)
        case .ignoreConfirmed:
            Task { await ignoreUser() }
        case .unignoreConfirmed:
            Task { await unignoreUser() }
        case .displayAvatar:
            displayFullScreenAvatar()
        case .openDirectChat:
            guard let roomMemberProxy else {
                fatalError()
            }
            
            actionsSubject.send(.openDirectChat(displayName: roomMemberProxy.displayName))
        }
    }

    // MARK: - Private

    @MainActor
    private func ignoreUser() async {
        guard let roomMemberProxy else {
            fatalError()
        }
        
        state.isProcessingIgnoreRequest = true
        let result = await roomMemberProxy.ignoreUser()
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            state.memberDetails?.isIgnored = true
            updateMembers()
        case .failure:
            state.bindings.alertInfo = .init(id: .unknown)
        }
    }

    @MainActor
    private func unignoreUser() async {
        guard let roomMemberProxy else {
            fatalError()
        }
        
        state.isProcessingIgnoreRequest = true
        let result = await roomMemberProxy.unignoreUser()
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            state.memberDetails?.isIgnored = false
            updateMembers()
        case .failure:
            state.bindings.alertInfo = .init(id: .unknown)
        }
    }

    private func updateMembers() {
        Task.detached {
            await self.roomProxy.updateMembers()
        }
    }
    
    private func displayFullScreenAvatar() {
        guard let roomMemberProxy else {
            fatalError()
        }
        
        guard let avatarURL = roomMemberProxy.avatarURL else {
            return
        }
        
        let loadingIndicatorIdentifier = "roomMemberAvatarLoadingIndicator"
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
        
        Task {
            defer {
                userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier)
            }
            
            // We don't actually know the mime type here, assume it's an image.
            if case let .success(file) = await mediaProvider.loadFileFromSource(.init(url: avatarURL, mimeType: "image/jpeg")) {
                state.bindings.mediaPreviewItem = MediaPreviewItem(file: file, title: roomMemberProxy.displayName)
            }
        }
    }
    
    // MARK: Loading indicator
    
    private static let loadingIndicatorIdentifier = "RoomMemberLoading"
    
    private func showMemberLoadingIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: false, allowsInteraction: true),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: .milliseconds(100))
    }
    
    private func hideMemberLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
