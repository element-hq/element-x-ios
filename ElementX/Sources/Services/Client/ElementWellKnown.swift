//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct ElementWellKnown {
    let registrationHelperURL: URL?
    
    init?(_ wellKnown: MatrixRustSDK.ElementWellKnown) {
        registrationHelperURL = wellKnown.registrationHelperUrl.flatMap(URL.init)
    }
}
