//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// The play badge drawn over video thumbnails, in the timeline and on the media viewer's posters.
struct VideoPlayBadge: View {
    var body: some View {
        CompoundIcon(\.playSolid, size: .medium, relativeTo: .compound.headingLG)
            .foregroundStyle(.compound.iconPrimary)
            .padding(13)
            .background {
                ZStack {
                    Circle().fill(.compound.bgSubtleSecondary)
                    Circle().stroke(.compound.borderInteractiveSecondary)
                }
            }
    }
}
