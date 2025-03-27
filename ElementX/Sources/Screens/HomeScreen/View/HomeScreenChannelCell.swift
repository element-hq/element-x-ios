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
    
    var attributedDisplayName: AttributedString {
        var channelAttributedName = AttributedString(channel.displayName)
        if channel.notificationsCount > 0 {
            if let prefixRange = channelAttributedName.range(of: ZeroContants.ZERO_CHANNEL_PREFIX) {
                channelAttributedName[prefixRange].foregroundColor = .compound.textSecondary
            }
        }
        return channelAttributedName
    }
    
    var body: some View {
        HStack {
            Text(attributedDisplayName)
                .font(.zero.bodyLG)
                .foregroundStyle(channel.notificationsCount > 0 ? .compound.textPrimary : .compound.textSecondary)
                .lineLimit(1)
            
            Spacer()
            
            if channel.notificationsCount > 0 {
                Circle()
                    .frame(width: 6, height: 6)
                    .foregroundStyle(.zero.bgAccentRest)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            onChannelSelected(channel)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 24)
    }
}
