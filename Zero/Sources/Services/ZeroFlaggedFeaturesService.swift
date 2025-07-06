//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

class ZeroFlaggedFeaturesService {
    static let shared = ZeroFlaggedFeaturesService()
    
    private var isZeroWalletEnabled: Bool = false
    
    private init() {}
    
    func zeroWalletEnabled() -> Bool {
        return isZeroWalletEnabled
    }
}
