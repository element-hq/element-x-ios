//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import UIKit

struct ManageWalletsViewState: BindableState {
    var bindings: ManageWalletsViewStateBindings
    
    var wallets: [ZeroWallet] = []
    
    var selfCustodyWallets: [ZeroWallet]  {
        wallets.filter { $0.canAuthenticate }
    }
    var zeroWallets: [ZeroWallet]  {
        wallets.filter { ($0.isThirdWeb) }
    }
}

struct ManageWalletsViewStateBindings {
    
}

enum ManageWalletsViewAction {
    case onWalletSelected(ZeroWallet)
}

struct ZeroWallet: Identifiable, Equatable {
    let id: String
    let address: String
    let isDefault: Bool
    let canAuthenticate: Bool
    let isThirdWeb: Bool
}

extension ZeroWallet {
    init(wallet: ZWallet) {
        self.init(
            id: wallet.id,
            address: wallet.publicAddress,
            isDefault: wallet.isDefault,
            canAuthenticate: wallet.canAuthenticate ?? false,
            isThirdWeb: wallet.isThirdWeb
        )
    }
    
    var zcanLiveUrl: URL? {
        URL(string: "\(ZeroContants.ZERO_WALLET_ZSCAN_LIVE_URL)address/\(address)")
    }
}
