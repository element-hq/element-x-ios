//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The trailing navigation bar item shown while messages are being selected in a timeline.
struct TimelineSelectionToolbar: ToolbarContent {
    let onClose: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            Button(action: onClose) {
                CompoundIcon(\.close)
            }
            .accessibilityLabel(L10n.actionClose)
        }
    }
}
