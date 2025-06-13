//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomeContentEmptyView: View {
    let message: String
    
    var body: some View {
        ZStack(alignment: .center) {
            Text(message)
                .font(.compound.headingMD)
                .foregroundColor(.compound.textSecondary)
                .frame(maxWidth: .infinity)
        }
        .frame(maxWidth: .infinity, minHeight: 300)
    }
}
