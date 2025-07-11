//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI
import StoreKitPlus
import StoreKit

typealias ZeroProSubcriptionScreenViewModelType = StateStoreViewModel<ZeroProSubcriptionScreenViewState, ZeroProSubcriptionScreenViewAction>

class ZeroProSubcriptionScreenViewModel: ZeroProSubcriptionScreenViewModelType, ZeroProSubcriptionScreenViewModelProtocol {
    
    private let clientProxy: ClientProxyProtocol
    private let storeContext: StoreContext
    private let storeService: StandardStoreService
    
    private var zeroProSubscriptionProduct: Product?
    
    init(userSession: UserSessionProtocol) {
        self.clientProxy = userSession.clientProxy
        // Initialize StoreKit
        let products = ZeroSubscriptions.allCases
        storeContext = StoreContext()
        storeService = StandardStoreService(products: products)
        
        super.init(
            initialViewState: .init(bindings: .init())
        )
        
        userSession.clientProxy.zeroCurrentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
                self?.state.currentUser = currentUser
                self?.state.isZeroProSubscriber = currentUser.subscriptions.zeroPro
            }
            .store(in: &cancellables)
        
        // Sync StoreKit
        syncStoreKit()
        
        // Fetch Zero Pro Subscription Product
        fetchZeroProSubscription()
    }
    
    override func process(viewAction: ZeroProSubcriptionScreenViewAction) {
        switch viewAction {
        case .purchaseSubscriptionTapped:
            purchaseZeroProSubscription()
        }
    }
    
    private func syncStoreKit() {
        Task {
            do {
                try await storeService.syncStoreData(to: storeContext)
            } catch {
                MXLog.error("Failed to sync store data: \(error)")
            }
        }
    }
    
    private func fetchZeroProSubscription() {
        Task {
            do {
                let products = try await storeService.getProducts()
                if let zeroProSubscription = products.first {
                    zeroProSubscriptionProduct = zeroProSubscription
                    state.canPurchaseSubscription = true
                } else {
                    state.canPurchaseSubscription = false
                }
            } catch {
                MXLog.error("Failed to fetch zero pro subscription product: \(error)")
                state.canPurchaseSubscription = false
            }
        }
    }
    
    private func purchaseZeroProSubscription() {
        guard let zeroProSubscriptionProduct else {
            return
        }
        Task {
            do {
                var options: Set<Product.PurchaseOption> = []
                if let currentUser = state.currentUser {
                    options.insert(.custom(key: "user_id", value: currentUser.id.rawValue))
                }
                let result = try await storeService.purchase(zeroProSubscriptionProduct, options: options)
                if case .success(_) = result.0 {
                    clientProxy.fetchZCurrentUser()
                }
                syncStoreKit()
            } catch {
                MXLog.error("Failed to purchase zero pro subscription: \(error)")
            }
        }
    }
}
