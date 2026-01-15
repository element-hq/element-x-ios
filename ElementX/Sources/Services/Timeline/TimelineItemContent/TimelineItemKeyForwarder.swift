//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import MatrixRustSDK
import SwiftUI

struct TimelineItemKeyForwarder: Identifiable, Hashable {
    let id: String
    let displayName: String?
    
    init(id: String, displayName: String? = nil) {
        self.id = id
        self.displayName = displayName
    }
    
    init(forwarderID: String, forwarderProfile: ProfileDetails) {
        switch forwarderProfile {
        case let .ready(displayName, _, _):
            self.init(id: forwarderID,
                      displayName: displayName)
        default:
            self.init(id: forwarderID,
                      displayName: nil)
        }
    }
    
    var message: String {
        if let displayName {
            L10n.cryptoEventKeyForwardedKnownProfileDialogContent(displayName, id)
        } else {
            L10n.cryptoEventKeyForwardedUnknownProfileDialogContent(id)
        }
    }
}
