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
    private let roomProxy: JoinedRoomProxyProtocol
    private let clientProxy: ClientProxyProtocol
    private let mediaProvider: MediaProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let analytics: AnalyticsService
    
    private var actionsSubject: PassthroughSubject<RoomMemberDetailsScreenViewModelAction, Never> = .init()
    
    private var roomMemberProxy: RoomMemberProxyProtocol?
    
    var actions: AnyPublisher<RoomMemberDetailsScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userID: String,
         roomProxy: JoinedRoomProxyProtocol,
         clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         analytics: AnalyticsService) {
        self.roomProxy = roomProxy
        self.clientProxy = clientProxy
        self.mediaProvider = mediaProvider
        self.userIndicatorController = userIndicatorController
        self.analytics = analytics
        
        let initialViewState = RoomMemberDetailsScreenViewState(userID: userID, bindings: .init())
        
        super.init(initialViewState: initialViewState, mediaProvider: mediaProvider)
        
        showMemberLoadingIndicator()
        Task {
            defer {
                hideMemberLoadingIndicator()
            }
            
            switch await roomProxy.getMember(userID: userID) {
            case .success(let member):
                roomMemberProxy = member
                state.memberDetails = RoomMemberDetails(withProxy: member)
                state.isOwnMemberDetails = member.userID == roomProxy.ownUserID
                switch await clientProxy.directRoomForUserID(member.userID) {
                case .success(let roomID):
                    state.dmRoomID = roomID
                case .failure:
                    break
                }
            case .failure(let error):
                MXLog.warning("Failed to find member: \(error)")
                actionsSubject.send(.openUserProfile)
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
            Task { await displayFullScreenAvatar() }
        case .openDirectChat:
            Task { await openDirectChat() }
        case .startCall(let roomID):
            actionsSubject.send(.startCall(roomID: roomID))
        }
    }

    // MARK: - Private

    @MainActor
    private func ignoreUser() async {
        guard let roomMemberProxy else {
            fatalError()
        }
        
        state.isProcessingIgnoreRequest = true
        let result = await clientProxy.ignoreUser(roomMemberProxy.userID)
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            var details = state.memberDetails
            details?.isIgnored = true
            state.memberDetails = details
            
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
        let result = await clientProxy.unignoreUser(roomMemberProxy.userID)
        state.isProcessingIgnoreRequest = false
        switch result {
        case .success:
            var details = state.memberDetails
            details?.isIgnored = false
            state.memberDetails = details
            
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
    
    private func displayFullScreenAvatar() async {
        guard let roomMemberProxy else {
            fatalError()
        }
        
        guard let avatarURL = roomMemberProxy.avatarURL else {
            return
        }
        
        let loadingIndicatorIdentifier = "roomMemberAvatarLoadingIndicator"
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
        defer { userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier) }
            
        // We don't actually know the mime type here, assume it's an image.
        if case let .success(file) = await mediaProvider.loadFileFromSource(.init(url: avatarURL, mimeType: "image/jpeg")) {
            state.bindings.mediaPreviewItem = MediaPreviewItem(file: file, title: roomMemberProxy.displayName)
        }
    }
    
    private func openDirectChat() async {
        guard let roomMemberProxy else { fatalError() }
        
        let loadingIndicatorIdentifier = "openDirectChatLoadingIndicator"
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonLoading,
                                                              persistent: true))
        defer { userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier) }
        
        switch await clientProxy.createDirectRoomIfNeeded(with: roomMemberProxy.userID, expectedRoomName: roomMemberProxy.displayName) {
        case .success((let roomID, let isNewRoom)):
            if isNewRoom {
                analytics.trackCreatedRoom(isDM: true)
            }
            actionsSubject.send(.openDirectChat(roomID: roomID))
        case .failure:
            state.bindings.alertInfo = .init(id: .failedOpeningDirectChat)
        }
    }
    
    // MARK: Loading indicator
    
    private static let loadingIndicatorIdentifier = "\(RoomMemberDetailsScreenViewModel.self)-Loading"
    
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
