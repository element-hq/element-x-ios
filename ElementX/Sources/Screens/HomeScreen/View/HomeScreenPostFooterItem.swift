//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomeScreenPostFooterItem: View {
    
    let icon: ImageAsset
    let count: String
    let highlightColor: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 2) {
                Image(asset: icon)
                    .foregroundStyle(highlightColor ? .zero.bgAccentRest : .compound.textSecondary)
                if !count.isEmpty {
                    Text("\(count)")
                        .font(.zero.bodyMD)
                        .foregroundStyle(highlightColor ? .zero.bgAccentRest : .compound.textSecondary)
                }
            }
        }
    }
}
