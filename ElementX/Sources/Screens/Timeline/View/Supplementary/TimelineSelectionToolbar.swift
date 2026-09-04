//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The navigation bar content shown while messages are being selected in a timeline.
struct TimelineSelectionToolbar: ToolbarContent {
    let count: Int
    let onCancel: () -> Void
    
    var body: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel, role: .cancel, action: onCancel)
        }
        
        ToolbarItem(placement: .principal) {
            Text(L10n.screenRoomSelectionCount(count))
                .font(.compound.bodyLGSemibold)
                .foregroundStyle(.compound.textPrimary)
        }
    }
}
