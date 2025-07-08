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
    
    private let storeContext: StoreContext
    private let storeService: StandardStoreService
    
    private var zeroProSubscriptionProduct: Product?
    
    init(userSession: UserSessionProtocol) {
        
        // Initialize StoreKit
        let products = ZeroSubscriptions.allCases
        storeContext = StoreContext()
        storeService = StandardStoreService(products: products)
        let available = products.available(in: storeContext)
        let purchased = products.purchased(in: storeContext)
        
        super.init(
            initialViewState: .init(bindings: .init())
        )
        
        userSession.clientProxy.zeroCurrentUserPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] currentUser in
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
                let result = try await storeService.purchase(zeroProSubscriptionProduct, options: [
                    .custom(key: "user_id", value: ""),
                    .custom(key: "user_email", value: "")
                ])
                syncStoreKit()
            } catch {
                MXLog.error("Failed to purchase zero pro subscription: \(error)")
            }
        }
    }
}
