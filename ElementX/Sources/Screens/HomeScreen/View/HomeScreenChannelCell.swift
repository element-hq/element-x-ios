//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomeScreenChannelCell: View {
    let channel: HomeScreenChannel
    let onChannelSelected: (HomeScreenChannel) -> Void
    
    var body: some View {
        Text(channel.displayName)
            .font(.zero.bodyLG)
            .foregroundStyle(.compound.textPrimary)
            .padding(.vertical, 12)
            .padding(.horizontal, 24)
            .onTapGesture {
                onChannelSelected(channel)
            }
    }
}
