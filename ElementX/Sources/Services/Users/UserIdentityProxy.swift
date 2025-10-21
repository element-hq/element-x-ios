//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK

class UserIdentityProxy: UserIdentityProxyProtocol {
    private let userIdentity: UserIdentity
    
    init(userIdentity: UserIdentity) {
        self.userIdentity = userIdentity
    }
    
    var verificationState: UserIdentityVerificationState {
        if userIdentity.hasVerificationViolation() {
            return .verificationViolation
        } else if userIdentity.isVerified() {
            return .verified
        }
        
        return .notVerified
    }
}
