//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK
import MatrixRustSDKMocks

nonisolated extension ClientBuilderSDKMock {
    struct Configuration {
        var disableWellKnownLookup = false
    }
    
    enum MockError: Error { case generic }
    
    convenience init(_ configuration: Configuration) {
        self.init()
        
        disableWellKnownLookupDisableWellKnownLookupReturnValue = self
    }
}
