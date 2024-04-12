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
import MatrixRustSDK
import SwiftUI

typealias UserProfileScreenViewModelType = StateStoreViewModel<UserProfileScreenViewState, UserProfileScreenViewAction>

class UserProfileScreenViewModel: UserProfileScreenViewModelType, UserProfileScreenViewModelProtocol {
    private let clientProxy: ClientProxyProtocol
    private let mediaProvider: MediaProviderProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var actionsSubject: PassthroughSubject<UserProfileScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<UserProfileScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(userID: String,
         clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.clientProxy = clientProxy
        self.mediaProvider = mediaProvider
        self.userIndicatorController = userIndicatorController
        
        let initialViewState = UserProfileScreenViewState(userID: userID,
                                                          isOwnUser: userID == clientProxy.userID,
                                                          bindings: .init())
        
        super.init(initialViewState: initialViewState, imageProvider: mediaProvider)
        
        showMemberLoadingIndicator()
        Task {
            defer {
                hideMemberLoadingIndicator()
            }
            
            switch await clientProxy.profile(for: userID) {
            case .success(let userProfile):
                state.userProfile = userProfile
                state.permalink = (try? matrixToUserPermalink(userId: userID)).flatMap(URL.init(string:))
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
        
        hideMemberLoadingIndicator()
    }
    
    override func process(viewAction: UserProfileScreenViewAction) {
        switch viewAction {
        case .displayAvatar:
            displayFullScreenAvatar()
        case .openDirectChat:
            guard let userProfile = state.userProfile else { fatalError() }
            actionsSubject.send(.openDirectChat(displayName: userProfile.displayName))
        }
    }

    // MARK: - Private
    
    private func displayFullScreenAvatar() {
        guard let userProfile = state.userProfile else { fatalError() }
        guard let avatarURL = userProfile.avatarURL else { return }
        
        let loadingIndicatorIdentifier = "roomMemberAvatarLoadingIndicator"
        userIndicatorController.submitIndicator(UserIndicator(id: loadingIndicatorIdentifier, type: .modal, title: L10n.commonLoading, persistent: true))
        
        Task {
            defer {
                userIndicatorController.retractIndicatorWithId(loadingIndicatorIdentifier)
            }
            
            // We don't actually know the mime type here, assume it's an image.
            if case let .success(file) = await mediaProvider.loadFileFromSource(.init(url: avatarURL, mimeType: "image/jpeg")) {
                state.bindings.mediaPreviewItem = MediaPreviewItem(file: file, title: userProfile.displayName)
            }
        }
    }
    
    // MARK: Loading indicator
    
    private static let loadingIndicatorIdentifier = "\(UserProfileScreenViewModel.self)-Loading"
    
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
