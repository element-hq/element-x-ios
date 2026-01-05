//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

extension IdentityResetHandleSDKMock {
    struct Configuration { }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        authTypeReturnValue = .uiaa
        resetAuthClosure = { _ in
            try await Task.sleep(for: .seconds(60))
        }
    }
}
