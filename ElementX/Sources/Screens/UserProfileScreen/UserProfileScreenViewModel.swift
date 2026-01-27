//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI

typealias UserProfileScreenViewModelType = StateStoreViewModelV2<UserProfileScreenViewState, UserProfileScreenViewAction>

class UserProfileScreenViewModel: UserProfileScreenViewModelType, UserProfileScreenViewModelProtocol {
    private let userSession: UserSessionProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let analytics: AnalyticsService
    
    private var actionsSubject: PassthroughSubject<UserProfileScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<UserProfileScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userID: String,
         isPresentedModally: Bool,
         userSession: UserSessionProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         analytics: AnalyticsService) {
        self.userSession = userSession
        self.userIndicatorController = userIndicatorController
        self.analytics = analytics
        
        let initialViewState = UserProfileScreenViewState(userID: userID,
                                                          isOwnUser: userID == userSession.clientProxy.userID,
                                                          isPresentedModally: isPresentedModally,
                                                          bindings: .init())
        
        super.init(initialViewState: initialViewState, mediaProvider: userSession.mediaProvider)
        
        showLoadingIndicator(allowsInteraction: true)
        Task {
            await loadProfile()
            hideLoadingIndicator()
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
        case .displayAvatar(let url):
            Task { await displayFullScreenAvatar(url) }
        case .openDirectChat:
            openDirectChat()
        case .createDirectChat:
            Task { await createDirectChat() }
        case .startCall(let roomID):
            Task { await startCall(roomID: roomID) }
        case .dismiss:
            actionsSubject.send(.dismiss)
        }
    }

    // MARK: - Private
    
    private func loadProfile() async {
        async let profileResult = userSession.clientProxy.profile(for: state.userID)
        async let identityResult = userSession.clientProxy.userIdentity(for: state.userID, fallBackToServer: true)
        
        switch await profileResult {
        case .success(let userProfile):
            state.userProfile = userProfile
            state.permalink = (try? matrixToUserPermalink(userId: state.userID)).flatMap(URL.init(string:))
            
            switch userSession.clientProxy.directRoomForUserID(userProfile.userID) {
            case .success(let roomID):
                state.dmRoomID = roomID
            case .failure:
                break
            }
        case .failure(let error):
            state.bindings.alertInfo = .init(id: .unknown)
            MXLog.error("Failed to find user profile: \(error)")
        }
        
        if case let .success(.some(identity)) = await identityResult {
            state.isVerified = identity.verificationState == .verified
        } else {
            MXLog.error("Failed to find the user's identity.")
        }
    }
    
    private func displayFullScreenAvatar(_ url: URL) async {
        guard let userProfile = state.userProfile else { fatalError() }
        
        showLoadingIndicator(allowsInteraction: false)
        defer { hideLoadingIndicator() }
        
        // We don't actually know the mime type here, assume it's an image.
        if let mediaSource = try? MediaSourceProxy(url: url, mimeType: "image/jpeg"),
           case let .success(file) = await userSession.mediaProvider.loadFileFromSource(mediaSource) {
            state.bindings.mediaPreviewItem = MediaPreviewItem(file: file, title: userProfile.displayName)
        }
    }
    
    private func openDirectChat() {
        guard let userProfile = state.userProfile else { fatalError() }
        
        showLoadingIndicator(allowsInteraction: false)
        defer { hideLoadingIndicator() }
        
        switch userSession.clientProxy.directRoomForUserID(userProfile.userID) {
        case .success(let roomID):
            if let roomID {
                actionsSubject.send(.openDirectChat(roomID: roomID))
            } else {
                state.bindings.inviteConfirmationUser = userProfile
            }
        case .failure:
            state.bindings.alertInfo = .init(id: .failedOpeningDirectChat)
        }
    }
    
    private func createDirectChat() async {
        guard let userProfile = state.userProfile else { fatalError() }
        
        showLoadingIndicator(allowsInteraction: false)
        defer { hideLoadingIndicator() }
        
        switch await userSession.clientProxy.createDirectRoom(with: userProfile.userID, expectedRoomName: userProfile.displayName) {
        case .success(let roomID):
            analytics.trackCreatedRoom(isDM: true)
            actionsSubject.send(.openDirectChat(roomID: roomID))
        case .failure:
            state.bindings.alertInfo = .init(id: .failedOpeningDirectChat)
        }
    }
    
    private func startCall(roomID: String) async {
        guard case let .joined(roomProxy) = await userSession.clientProxy.roomForIdentifier(roomID) else {
            showErrorIndicator()
            return
        }
        actionsSubject.send(.startCall(roomProxy: roomProxy))
    }
    
    // MARK: User Indicators
    
    private var loadingIndicatorIdentifier: String {
        "\(Self.self)-Loading"
    }

    private var statusIndicatorIdentifier: String {
        "\(Self.self)-Status"
    }
    
    private func showLoadingIndicator(allowsInteraction: Bool) {
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: false, allowsInteraction: allowsInteraction),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: .milliseconds(100))
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier)
    }
    
    private func showErrorIndicator() {
        userIndicatorController.submitIndicator(UserIndicator(id: statusIndicatorIdentifier,
                                                              type: .toast,
                                                              title: L10n.errorUnknown,
                                                              iconName: "xmark"))
    }
}
