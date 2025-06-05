//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HorizontalDivider: View {
    var color: Color = .gray
    
    var body: some View {
        Rectangle()
            .fill(color.opacity(0.4))
            .frame(height: 1)
    }
}
