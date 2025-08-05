//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct TransferTokenViewState: BindableState {
    var isSearching = false
    var bindings: TransferTokenBindings
    
    var transferTokenFlowState: TransferTokenFlowState = .recipient
    var isNavigatingForward: Bool = true
    
    var currentUser: ZCurrentUser?
    var userAvatarURL: URL?
    var transferRecipient: WalletRecipient?
    var tokenAsset: ZWalletToken?
    
    var meowPrice: ZeroCurrency?
    
    // Recipient
    var recipientsListMode: WalletRecipientsListMode = .empty
    var placeholderRecipeints: [WalletRecipient] {
        (1...10).map { index in
            WalletRecipient.placeholder(index)
        }
    }
        
    // Token Assets
    var walletTokenNextPageParams: NextPageParams? = nil
    var walletTokensListMode: TokenAssetsListMode = .skeletons
    var placeholderTokens: [HomeScreenWalletContent] {
        (1...20).map { _ in
            HomeScreenWalletContent.placeholder()
        }
    }
    
    var showTopBarBackButton: Bool {
        switch transferTokenFlowState {
        case .recipient, .inProgress, .completed:
            return false
        default:
            return true
        }
    }
    
    var canMakeTransaction: Bool {
        transferRecipient != nil &&
        tokenAsset != nil &&
        !bindings.transferAmount.isEmpty &&
        (Double(bindings.transferAmount) ?? 0) > 0
    }
}

struct TransferTokenBindings {
    var alertInfo: AlertInfo<UUID>?
    var searchRecipientQuery = ""
    
    var transferAmount: String = ""
}

enum TransferTokenViewModelAction {
    case transactionCompleted
    case finished
}

enum TransferTokenViewAction {
    case goToFlowState(TransferTokenFlowState)
    case onRecipientSelected(WalletRecipient)
    case loadMoreTokenAssets
    case onTokenAssetSelected(HomeScreenWalletContent)
    case onTransactionConfirmed
    case viewTransaction
    
    case transactionCompleted
}

enum WalletRecipientsListMode: CustomStringConvertible {
    case skeletons
    case empty
    case recipients([WalletRecipient])
    
    var description: String {
        switch self {
        case .skeletons:
            return "Showing placeholders"
        case .empty:
            return "Showing empty state"
        case .recipients(_):
            return "Showing recipients"
        }
    }
}

enum TokenAssetsListMode: CustomStringConvertible {
    case skeletons
    case empty
    case assets([HomeScreenWalletContent])
    
    var description: String {
        switch self {
        case .skeletons:
            return "Showing placeholders"
        case .empty:
            return "Showing empty state"
        case .assets(_):
            return "Showing token assets"
        }
    }
}

enum TransferTokenFlowState {
    case recipient
    case asset
    case confirmation
    case inProgress
    case completed
}
