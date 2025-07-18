//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ReceiveTransactionViewModelType = StateStoreViewModel<ReceiveTransactionViewState, ReceiveTransactionViewAction>

class ReceiveTransactionViewModel: ReceiveTransactionViewModelType, ReceiveTransactionViewModelProtocol {
    
    private let clientProxy: ClientProxyProtocol
    
    private var actionsSubject: PassthroughSubject<ReceiveTransactionViewModelAction, Never> = .init()
    var actions: AnyPublisher<ReceiveTransactionViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
        
    init(clientProxy: ClientProxyProtocol) {
        self.clientProxy = clientProxy
        
        super.init(
            initialViewState: .init(bindings: .init())
        )
        
        clientProxy.zeroCurrentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
                self?.state.currentUser = currentUser
            }
            .store(in: &cancellables)
    }
    
    override func process(viewAction: ReceiveTransactionViewAction) {
        switch viewAction {
        case .copyAddress:
            copyWalletAddress()
        case .finish:
            actionsSubject.send(.finish)
        }
    }
    
    private func copyWalletAddress() {
        if let address = state.currentUser?.publicWalletAddress {
            UIPasteboard.general.string = address
        }
    }
}
