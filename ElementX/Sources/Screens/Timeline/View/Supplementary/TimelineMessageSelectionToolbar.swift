//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// The trailing navigation bar item that cancels the selection of messages in a timeline.
struct TimelineMessageSelectionToolbar: ToolbarContent {
    let onCancel: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .primaryAction) {
            ToolbarButton(role: .cancel, action: onCancel)
        }
    }
}
