//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import MatrixRustSDK

struct ElementWellKnown {
    struct Call {
        let widgetURL: URL
        
        init?(_ wellKnown: MatrixRustSDK.ElementCallWellKnown) {
            guard let widgetURL = URL(string: wellKnown.widgetUrl) else { return nil }
            self.widgetURL = widgetURL
        }
    }
    
    let call: Call?
    let registrationHelperURL: URL?
    
    init?(_ wellKnown: MatrixRustSDK.ElementWellKnown) {
        call = wellKnown.call.flatMap(Call.init)
        registrationHelperURL = wellKnown.registrationHelperUrl.flatMap(URL.init)
    }
}
