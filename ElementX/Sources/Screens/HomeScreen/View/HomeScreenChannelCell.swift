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
        HStack {
            Text(channel.displayName)
                .font(.zero.bodyLG)
                .foregroundStyle(.compound.textPrimary)
                .lineLimit(1)
            
            Spacer()
            
            if channel.notificationsCount > 0 {
                Text(channel.notificationsCount > 99 ? "99+" : String(channel.notificationsCount))
                    .font(.compound.bodyXSSemibold)
                    .foregroundStyle(.zero.bgAccentRest)
                    .background {
                        Circle()
                            .frame(width: 20, height: 20)
                            .foregroundStyle(.zero.bgAccentRest.opacity(0.2))
                    }
            }
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
        .onTapGesture {
            onChannelSelected(channel)
        }
    }
}
