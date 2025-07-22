//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias CreateFeedScreenViewModelType = StateStoreViewModel<CreateFeedScreenViewState, CreateFeedScreenViewAction>

class CreateFeedScreenViewModel: CreateFeedScreenViewModelType, CreateFeedScreenViewModelProtocol, FeedMediaSelectedProtocol {
    
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let feedProtocol: FeedProtocol
    
    private var currentUserWalletAddress: String? = nil
    private var defaultChannelZId: String? = nil
    
    private var actionsSubject: PassthroughSubject<CreateFeedScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<CreateFeedScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(clientProxy: ClientProxyProtocol,
         feedProtocol: FeedProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         mediaProvider: MediaProviderProtocol,
         fromUserProfileFlow: Bool) {
        self.clientProxy = clientProxy
        self.feedProtocol = feedProtocol
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(userID: clientProxy.userID,
                                           showCloseButton: !fromUserProfileFlow,
                                           bindings: .init()), mediaProvider: mediaProvider)
        
        clientProxy.userAvatarURLPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userAvatarURL, on: self)
            .store(in: &cancellables)
        
        clientProxy.zeroCurrentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
                self?.currentUserWalletAddress = currentUser.thirdWebWalletAddress
                self?.defaultChannelZId = currentUser.primaryZID
            }
            .store(in: &cancellables)
    }
    
    override func process(viewAction: CreateFeedScreenViewAction) {
        switch viewAction {
        case .createPost:
            createNewPost()
        case .dismissPost:
            actionsSubject.send(.dismissPost)
        case .attachMedia:
            actionsSubject.send(.attachMedia(self))
        case .deleteMedia:
            state.bindings.selectedFeedMediaUrl = nil
        }
    }
    
    private func createNewPost() {
//        guard let userWalletAddress = currentUserWalletAddress else {
//            state.bindings.alertInfo = .init(id: UUID(),
//                                             title: L10n.commonError,
//                                             message: "User default wallet is not initialized.")
//            return
//        }
        guard let defaultChannelZId = defaultChannelZId else {
            state.bindings.alertInfo = .init(id: UUID(),
                                             title: L10n.commonError,
                                             message: "Please set user primaryZId in profile settings.")
            return
        }
        
        Task {
            let userIndicatorID = UUID().uuidString
            defer {
                userIndicatorController.retractIndicatorWithId(userIndicatorID)
            }
            userIndicatorController.submitIndicator(UserIndicator(id: userIndicatorID,
                                                                  type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                                  title: "Posting...",
                                                                  persistent: true))
            
            let postFeedResult = await clientProxy.postNewFeed(channelZId: defaultChannelZId,
                                                               content: state.bindings.feedText,
                                                               replyToPost: nil,
                                                               mediaFile: state.bindings.selectedFeedMediaUrl)
            switch postFeedResult {
            case .success:
                feedProtocol.onNewFeedPosted()
                actionsSubject.send(.newFeedPosted)
            case .failure(_):
                state.bindings.alertInfo = .init(id: UUID(),
                                                 title: L10n.commonError,
                                                 message: L10n.errorUnknown)
            }
        }
    }
    
    func onMediaSelected(media: URL) {
        state.bindings.selectedFeedMediaUrl = media
    }
}
