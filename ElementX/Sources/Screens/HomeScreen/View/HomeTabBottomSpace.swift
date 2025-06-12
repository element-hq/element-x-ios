//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomeTabBottomSpace : View {
    var spacerHeight: CGFloat = 100
    
    var body: some View {
        Rectangle()
            .fill(Color.clear)
            .frame(height: spacerHeight)
    }
}
