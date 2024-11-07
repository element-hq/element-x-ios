//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

extension UserIdentitySDKMock {
    struct Configuration {
        var isVerified = false
    }
    
    convenience init(configuration: Configuration) {
        self.init()
        
        isVerifiedReturnValue = configuration.isVerified
    }
}
