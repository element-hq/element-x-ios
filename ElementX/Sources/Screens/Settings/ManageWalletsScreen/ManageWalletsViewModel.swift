//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias ManageWalletsViewModelType = StateStoreViewModel<ManageWalletsViewState, ManageWalletsViewAction>

class ManageWalletsViewModel: ManageWalletsViewModelType, ManageWalletsViewModelProtocol {
    
    private let clientProxy: ClientProxyProtocol
    private let userIndicatorController: UserIndicatorControllerProtocol

    init(userSession: UserSessionProtocol,
         userIndicatorController: UserIndicatorControllerProtocol) {
        
        self.clientProxy = userSession.clientProxy
        self.userIndicatorController = userIndicatorController
        
        super.init(initialViewState: .init(bindings: .init()))
        
        fetchUserWallets()
    }
    
    override func process(viewAction: ManageWalletsViewAction) {
        switch viewAction {
        case .onWalletSelected(let wallet):
            openWalletAddress(wallet)
        }
    }
    
    private func fetchUserWallets() {
        Task {
            showLoadingIndicator()
            defer { hideLoadingIndicator() }
            
            let result = await clientProxy.fetchUserWallets()
            switch result {
            case .success(let wallets):
                state.wallets = wallets.map(ZeroWallet.init)
            case .failure(let error):
                //TODO: show error dialog
                break
            }
        }
    }
    
    private func openWalletAddress(_ wallet: ZeroWallet) {
        if let url = wallet.zcanLiveUrl {
            UIApplication.shared.open(url)
        }
    }
    
    // MARK: Loading indicator
    
    private static let loadingIndicatorIdentifier = "\(ManageWalletsViewModel.self)-Loading"
    
    private func showLoadingIndicator(delay: Duration? = nil) {
        userIndicatorController.submitIndicator(UserIndicator(id: Self.loadingIndicatorIdentifier,
                                                              type: .modal(progress: .indeterminate, interactiveDismissDisabled: true, allowsInteraction: false),
                                                              title: L10n.commonLoading,
                                                              persistent: true),
                                                delay: delay)
    }
    
    private func hideLoadingIndicator() {
        userIndicatorController.retractIndicatorWithId(Self.loadingIndicatorIdentifier)
    }
}
