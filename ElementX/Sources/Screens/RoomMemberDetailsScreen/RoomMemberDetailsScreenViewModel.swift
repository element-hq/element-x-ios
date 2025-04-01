//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
            await loadMember()
            hideMemberLoadingIndicator()
        }
        
        roomProxy.identityStatusChangesPublisher
            .receive(on: DispatchQueue.main)
            .sink { changes in
                if changes.map(\.userId).contains(userID) {
                    Task { await self.loadMember() }
                }
            }
            .store(in: &cancellables)
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
        case .displayAvatar(let url):
            Task { await displayFullScreenAvatar(url) }
        case .openDirectChat:
            openDirectChat()
        case .createDirectChat:
            Task { await createDirectChat() }
        case .startCall(let roomID):
            actionsSubject.send(.startCall(roomID: roomID))
        case .verifyUser:
            actionsSubject.send(.verifyUser(userID: state.userID))
        case .withdrawVerification:
            Task { await clientProxy.withdrawUserIdentityVerification(state.userID) }
        }
    }

    // MARK: - Private
    
    private func loadMember() async {
        switch await roomProxy.getMember(userID: state.userID) {
        case .success(let member):
            roomMemberProxy = member
            state.memberDetails = RoomMemberDetails(withProxy: member)
            state.isOwnMemberDetails = member.userID == roomProxy.ownUserID
            switch clientProxy.directRoomForUserID(member.userID) {
            case .success(let roomID):
                state.dmRoomID = roomID
            case .failure:
                break
            }
        case .failure(let error):
            MXLog.warning("Failed to find member: \(error)")
            // As we didn't find a member with the specified user ID in this room we instead
            // fall back to showing a generic user profile screen as the source is likely
            // a message containing a permalink to someone who's not in this room.
            actionsSubject.send(.openUserProfile)
        }
        
        if case let .success(.some(identity)) = await clientProxy.userIdentity(for: state.userID) {
            state.verificationState = identity.verificationState
        } else {
            MXLog.error("Failed to find the member's identity.")
        }
    }
    
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
    
    private func displayFullScreenAvatar(_ url: URL) async {
        guard let roomMemberProxy else {
            fatalError()
        }
        
        let loadingIndicatorIdentifier = "roomMemberAvatarLoadingIndicator"
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
        defer { userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier) }
            
        // We don't actually know the mime type here, assume it's an image.
        if let mediaSource = try? MediaSourceProxy(url: url, mimeType: "image/jpeg"),
           case let .success(file) = await mediaProvider.loadFileFromSource(mediaSource) {
            state.bindings.mediaPreviewItem = MediaPreviewItem(file: file, title: roomMemberProxy.displayName)
        }
    }
    
    private func openDirectChat() {
        guard let roomMemberProxy else { fatalError() }
        
        let loadingIndicatorIdentifier = "openDirectChatLoadingIndicator"
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: .milliseconds(200))
        defer { userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier) }
        
        switch clientProxy.directRoomForUserID(roomMemberProxy.userID) {
        case .success(let roomID):
            if let roomID {
                actionsSubject.send(.openDirectChat(roomID: roomID))
            } else {
                state.bindings.inviteConfirmationUser = .init(userID: roomMemberProxy.userID, displayName: roomMemberProxy.displayName, avatarURL: roomMemberProxy.avatarURL)
            }
        case .failure:
            state.bindings.alertInfo = .init(id: .failedOpeningDirectChat)
        }
    }
    
    private func createDirectChat() async {
        guard let roomMemberProxy else { fatalError() }

        let loadingIndicatorIdentifier = "createDirectChatLoadingIndicator"
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: .milliseconds(200))
        defer { userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier) }
        
        switch await clientProxy.createDirectRoom(with: roomMemberProxy.userID, expectedRoomName: roomMemberProxy.displayName) {
        case .success(let roomID):
            analytics.trackCreatedRoom(isDM: true)
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
