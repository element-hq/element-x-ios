//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

extension UserIdentityProxyMock {
    struct Configuration {
        var verificationState: UserIdentityVerificationState = .notVerified
    }
    
    convenience init(configuration: Configuration) {
        self.init()
        
        underlyingVerificationState = configuration.verificationState
    }
}
