//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import Foundation
import SwiftUI

struct CallNotificationRoomTimelineView: View {
    @EnvironmentObject private var context: TimelineViewModel.Context
    
    let timelineItem: CallNotificationRoomTimelineItem
    
    var body: some View {
        HStack(spacing: 12) {
            LoadableAvatarImage(url: timelineItem.sender.avatarURL,
                                name: timelineItem.sender.displayName ?? timelineItem.sender.id,
                                contentID: timelineItem.sender.id,
                                avatarSize: .user(on: .timeline),
                                mediaProvider: context.mediaProvider)
                .accessibilityHidden(true)
            
            VStack(alignment: .leading, spacing: 0) {
                Text(timelineItem.sender.disambiguatedDisplayName ?? timelineItem.sender.id)
                    .font(.compound.bodyLGSemibold)
                    .foregroundColor(.compound.textPrimary)
                    .lineLimit(1)
                    .frame(maxWidth: .infinity, alignment: .leading)
                
                Label(title: { Text(L10n.commonCallStarted) },
                      icon: { CompoundIcon(\.videoCallSolid, size: .medium, relativeTo: .compound.bodyMD) })
                    .font(.compound.bodyMD)
                    .foregroundColor(.compound.textSecondary)
                    .labelStyle(.custom(spacing: 4))
            }
            
            Spacer()
            
            Text(timelineItem.timestamp)
                .font(.compound.bodyXS)
                .foregroundColor(.compound.textSecondary)
        }
        .padding(12)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(.compound.borderInteractiveSecondary, lineWidth: 1)
        )
        .padding(16)
    }
}

struct CallNotificationRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        CallNotificationRoomTimelineView(timelineItem: .init(id: .random,
                                                             timestamp: "Now",
                                                             isEditable: false,
                                                             canBeRepliedTo: false,
                                                             sender: .init(id: "Bob")))
    }
}
