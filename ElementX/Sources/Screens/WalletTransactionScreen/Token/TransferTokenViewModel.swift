//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias TransferTokenViewModelType = StateStoreViewModel<TransferTokenViewState, TransferTokenViewAction>

class TransferTokenViewModel: TransferTokenViewModelType, TransferTokenViewModelProtocol {
    
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol
    
    private var _walletTokenAssets: [ZWalletToken] = []
    
    private var actionsSubject: PassthroughSubject<TransferTokenViewModelAction, Never> = .init()
    var actions: AnyPublisher<TransferTokenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
        
    init(clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(
            initialViewState: .init(bindings: .init()),
            mediaProvider: mediaProvider
        )
        
        clientProxy.zeroCurrentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
                self?.state.currentUser = currentUser
                self?.loadWalletTokenBalances()
            }
            .store(in: &cancellables)
        
        context.$viewState.map(\.bindings.searchRecipientQuery)
            .combineLatest(context.$viewState.map(\.isSearching)
            .filter { $0 == false })
            .map(\.0)
            .debounceTextQueriesAndRemoveDuplicates(debounceTimeMillis: 500)
            .sink { [weak self] query in
                self?.searchRecipient(query: query)
            }
            .store(in: &cancellables)
    }
    
    override func process(viewAction: TransferTokenViewAction) {
        switch viewAction {
        case .goToFlowState(let flowState):
            setFlowState(flowState, isNavigatingForward: false)
        case .onRecipientSelected(let recipient):
            state.transferRecipient = recipient
            setFlowState(.asset, isNavigatingForward: true)
        case .loadMoreTokenAssets:
            loadWalletTokenBalances()
        case .onTokenAssetSelected(let asset):
            state.tokenAsset = _walletTokenAssets.first { $0.tokenAddress == asset.id }
            setFlowState(.confirmation, isNavigatingForward: true)
        case .onTransactionConfirmed(let amount):
            performTokenTransaction(amount)
        case .transactionCompleted:
            actionsSubject.send(.finished)
        }
    }
    
    private func setFlowState(_ flowState: TransferTokenFlowState, isNavigatingForward: Bool = true) {
        state.isNavigatingForward = isNavigatingForward
        state.transferTokenFlowState = flowState
    }
    
    private func searchRecipient(query: String) {
        if query.isEmpty {
            state.recipientsListMode = .empty
        } else {
            Task {
                state.recipientsListMode = .skeletons
                let result = await clientProxy.searchTransactionRecipient(query: query)
                switch result {
                case .success(let recipients):
                    if recipients.isEmpty {
                        state.recipientsListMode = .empty
                    } else {
                        state.recipientsListMode = .recipients(recipients)
                    }
                case .failure(_):
                    state.recipientsListMode = .empty
                }
            }
        }
    }
    
    private func loadWalletTokenBalances() {
        if let walletAddress = state.currentUser?.publicWalletAddress {
            Task {
                let result = await clientProxy.getWalletTokenBalances(walletAddress: walletAddress, nextPage: state.walletTokenNextPageParams)
                if case .success(let walletTokenBalances) = result {
                    _walletTokenAssets = walletTokenBalances.tokens
                    var homeWalletContent: [HomeScreenWalletContent] = if case .assets(let tokens) = state.walletTokensListMode {
                        tokens
                    } else { [] }
                    for token in walletTokenBalances.tokens {
                        let content = HomeScreenWalletContent(walletToken: token)
                        homeWalletContent.append(content)
                    }
                    let uniqueAssets = homeWalletContent.uniqued(on: \.id)
                    state.walletTokenNextPageParams = walletTokenBalances.nextPageParams
                    state.walletTokensListMode = uniqueAssets.isEmpty ? .empty : .assets(uniqueAssets)
                }
            }
        }
    }
    
    private func performTokenTransaction(_ amount: String) {
        if let currentUserAddress = state.currentUser?.publicWalletAddress,
           let recipient = state.transferRecipient,
           let token = state.tokenAsset {
            showLoadingIndicator(title: "Sending...")
            Task {
                defer { hideLoadingIndicator() }
                
                let result = await clientProxy.transferToken(senderWalletAddress: currentUserAddress,
                                                             recipientWalletAddress: recipient.publicAddress,
                                                             amount: amount,
                                                             tokenAddress: token.tokenAddress)
                switch result {
                case .success(_):
                    state.tokenAmount = amount
                    setFlowState(.completed, isNavigatingForward: true)
                    actionsSubject.send(.transactionCompleted)
                case .failure(let failure):
                    MXLog.error("Failed to transfer token: \(failure)")
                    showError(error: failure.localizedDescription)
                }
            }
        }
    }
    
    private static let loadingIndicatorID = "\(UserFeedProfileFlowCoordinator.self)-Loading"
    
    private func showLoadingIndicator(delay: Duration? = nil, title: String = L10n.commonLoading) {
        userIndicatorController.submitIndicator(.init(id: Self.loadingIndicatorID,
                                                      type: .modal(progress: .indeterminate,
                                                                   interactiveDismissDisabled: false,
                                                                   allowsInteraction: false),
                                                      title: title, persistent: true),
                                                delay: delay)
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorID)
    }
    
    private func showError(error: String) {
        userIndicatorController.alertInfo = AlertInfo(id: UUID(),
                                                      title: "Transaction Failed",
                                                      message: error)
    }
}
