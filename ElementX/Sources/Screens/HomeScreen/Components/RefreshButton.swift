//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RefreshButton : View {
    let onRefresh: () -> Void
    var size: CGFloat = 30
    
    var body: some View {
        Button {
            onRefresh()
        } label: {
            Image(systemName: "arrow.clockwise")
                .resizable()
                .frame(width: (size - 5), height: size)
        }
    }
}
