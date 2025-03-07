//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias CreateFeedScreenViewModelType = StateStoreViewModel<CreateFeedScreenViewState, CreateFeedScreenViewAction>

class CreateFeedScreenViewModel: CreateFeedScreenViewModelType, CreateFeedScreenViewModelProtocol {
    
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    private let createFeedProtocol: CreateFeedProtocol
    
    private var currentUserWalletAddress: String? = nil
    private var defaultChannelZId: String? = nil
    
    private var actionsSubject: PassthroughSubject<CreateFeedScreenViewModelAction, Never> = .init()
    var actions: AnyPublisher<CreateFeedScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(clientProxy: ClientProxyProtocol,
         createFeedProtocol: CreateFeedProtocol,
         userIndicatorController: UserIndicatorControllerProtocol,
         mediaProvider: MediaProviderProtocol) {
        self.clientProxy = clientProxy
        self.createFeedProtocol = createFeedProtocol
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(userID: clientProxy.userID, bindings: .init()), mediaProvider: mediaProvider)
        
        clientProxy.userAvatarURLPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userAvatarURL, on: self)
            .store(in: &cancellables)
        
        fetchAndCheckCurrentUser()
    }
    
    override func process(viewAction: CreateFeedScreenViewAction) {
        switch viewAction {
        case .createPost:
            createNewPost()
        case .dismissPost:
            actionsSubject.send(.dismissPost)
        }
    }
    
    private func fetchAndCheckCurrentUser() {
        Task {
            if let (address, channelZId) = await fetchUserAddressAndChannelInfo(), !address.isEmpty {
                currentUserWalletAddress = address
                defaultChannelZId = channelZId
                return
            }
            // Initialize wallet and fetch details again
            _ = await clientProxy.initializeThirdWebWalletForUser()
            if let (nAddress, nChannelZId) = await fetchUserAddressAndChannelInfo() {
                currentUserWalletAddress = nAddress
                defaultChannelZId = nChannelZId
            }
        }
    }

    private func fetchUserAddressAndChannelInfo() async -> (address: String, channelZId: String)? {
        guard let user = await clientProxy.fetchCurrentZeroUser() else { return nil }
        let walletAddress = user.wallets?.first(where: { $0.isThirdWeb })?.publicAddress ?? ""
        let channelZId = user.primaryZID ?? ""
        return walletAddress.isEmpty ? nil : (walletAddress, channelZId)
    }
    
    private func createNewPost() {
        guard let userWalletAddress = currentUserWalletAddress else {
            state.bindings.alertInfo = .init(id: UUID(),
                                             title: L10n.commonError,
                                             message: "User default wallet is not initialized.")
            return
        }
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
                                                               userWalletAddress: userWalletAddress,
                                                               content: state.bindings.feedText,
                                                               replyToPost: nil)
            switch postFeedResult {
            case .success(_):
                createFeedProtocol.onNewFeedPosted()
                actionsSubject.send(.newFeedPosted)
            case .failure(_):
                state.bindings.alertInfo = .init(id: UUID(),
                                                 title: L10n.commonError,
                                                 message: L10n.errorUnknown)
            }
        }
    }
}
