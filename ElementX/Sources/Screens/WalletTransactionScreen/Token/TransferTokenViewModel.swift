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
    
    private var completedTransactionReceipt: ZWalletTransactionReceipt?
        
    init(meowPrice: ZeroCurrency?,
         clientProxy: ClientProxyProtocol,
         mediaProvider: MediaProviderProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        self.clientProxy = clientProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(
            initialViewState: .init(bindings: .init(), meowPrice: meowPrice),
            mediaProvider: mediaProvider
        )
        
        clientProxy.userAvatarURLPublisher
            .receive(on: DispatchQueue.main)
            .weakAssign(to: \.state.userAvatarURL, on: self)
            .store(in: &cancellables)
        
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
            setFlowState(.asset)
        case .loadMoreTokenAssets:
            loadWalletTokenBalances()
        case .onTokenAssetSelected(let asset):
            state.tokenAsset = _walletTokenAssets.first { $0.tokenAddress == asset.id }
            setFlowState(.confirmation)
        case .onTransactionConfirmed:
            performTokenTransaction()
        case .transactionCompleted:
            actionsSubject.send(.finished)
        case .viewTransaction:
            viewTransaction()
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
                        let content = HomeScreenWalletContent(walletToken: token, meowPrice: state.meowPrice)
                        homeWalletContent.append(content)
                    }
                    let uniqueAssets = homeWalletContent.uniqued(on: \.id)
                    state.walletTokenNextPageParams = walletTokenBalances.nextPageParams
                    state.walletTokensListMode = uniqueAssets.isEmpty ? .empty : .assets(uniqueAssets)
                }
            }
        }
    }
    
    private func performTokenTransaction() {
        if let currentUserAddress = state.currentUser?.publicWalletAddress,
           let recipient = state.transferRecipient,
           let token = state.tokenAsset {
            state.tokenAmount = amount
            Task {
                setFlowState(.inProgress)
                let result = await clientProxy.transferToken(senderWalletAddress: currentUserAddress,
                                                             recipientWalletAddress: recipient.publicAddress,
                                                             amount:  state.bindings.transferAmount,
                                                             tokenAddress: token.tokenAddress)
                switch result {
                case .success(let transaction):
                    setFlowState(.completed)
                    actionsSubject.send(.transactionCompleted)
                    getTransactionReceipt(transaction.transactionHash)
                case .failure(let failure):
                    MXLog.error("Failed to transfer token: \(failure)")
                    setFlowState(.failure)
                }
            }
        }
    }
    
    private func showError(error: String) {
        userIndicatorController.alertInfo = AlertInfo(id: UUID(),
                                                      title: "Transaction Failed",
                                                      message: error)
    }
    
    private func getTransactionReceipt(_ transactionHash: String) {
        Task.detached {
            if case .success(let receipt) = await self.clientProxy.getTransactionReceipt(transactionHash: transactionHash) {
                await MainActor.run {
                    self.completedTransactionReceipt = receipt
                }
            }
        }
    }
    
    private func viewTransaction() {
        if let receipt = completedTransactionReceipt, let link = URL(string: receipt.blockExplorerUrl) {
            UIApplication.shared.open(link)
        }
    }
}
