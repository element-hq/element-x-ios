//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias UserProfileScreenViewModelType = StateStoreViewModel<UserProfileScreenViewState, UserProfileScreenViewAction>

class UserProfileScreenViewModel: UserProfileScreenViewModelType, UserProfileScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let mediaProvider: MediaProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let analytics: AnalyticsService
    
    private var actionsSubject: PassthroughSubject<UserProfileScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<UserProfileScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userID: String,
         isPresentedModally: Bool,
         clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         analytics: AnalyticsService) {
        self.clientProxy = clientProxy
        self.mediaProvider = mediaProvider
        self.userIndicatorController = userIndicatorController
        self.analytics = analytics
        
        let initialViewState = UserProfileScreenViewState(userID: userID,
                                                          isOwnUser: userID == clientProxy.userID,
                                                          isPresentedModally: isPresentedModally,
                                                          bindings: .init())
        
        super.init(initialViewState: initialViewState, mediaProvider: mediaProvider)
        
        showLoadingIndicator(allowsInteraction: true)
        Task {
            defer {
                hideLoadingIndicator()
            }
            
            switch await clientProxy.profile(for: userID) {
            case .success(let userProfile):
                state.userProfile = userProfile
                state.permalink = (try? matrixToUserPermalink(userId: userID)).flatMap(URL.init(string:))
                switch await clientProxy.directRoomForUserID(userProfile.userID) {
                case .success(let roomID):
                    state.dmRoomID = roomID
                case .failure:
                    break
                }
            case .failure(let error):
                state.bindings.alertInfo = .init(id: .unknown)
                MXLog.error("Failed to find user profile: \(error)")
            }
        }
    }
    
    // MARK: - Public
    
    func stop() {
        // Work around QLPreviewController dismissal issues, see the InteractiveQuickLookModifier.
        state.bindings.mediaPreviewItem = nil
        
        hideLoadingIndicator()
    }
    
    override func process(viewAction: UserProfileScreenViewAction) {
        switch viewAction {
        case .displayAvatar:
            Task { await displayFullScreenAvatar() }
        case .openDirectChat:
            Task { await openDirectChat() }
        case .startCall(let roomID):
            actionsSubject.send(.startCall(roomID: roomID))
        case .dismiss:
            actionsSubject.send(.dismiss)
        }
    }

    // MARK: - Private
    
    private func displayFullScreenAvatar() async {
        guard let userProfile = state.userProfile else { fatalError() }
        guard let avatarURL = userProfile.avatarURL else { return }
        
        showLoadingIndicator(allowsInteraction: false)
        defer { hideLoadingIndicator() }
        
        // We don't actually know the mime type here, assume it's an image.
        if case let .success(file) = await mediaProvider.loadFileFromSource(.init(url: avatarURL, mimeType: "image/jpeg")) {
            state.bindings.mediaPreviewItem = MediaPreviewItem(file: file, title: userProfile.displayName)
        }
    }
    
    private func openDirectChat() async {
        guard let userProfile = state.userProfile else { fatalError() }
        
        showLoadingIndicator(allowsInteraction: false)
        defer { hideLoadingIndicator() }
            
        switch await clientProxy.createDirectRoomIfNeeded(with: userProfile.userID, expectedRoomName: userProfile.displayName) {
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
    
    private static let loadingIndicatorIdentifier = "\(UserProfileScreenViewModel.self)-Loading"
    
    private func showLoadingIndicator(allowsInteraction: Bool) {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: false, allowsInteraction: allowsInteraction),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: .milliseconds(100))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
