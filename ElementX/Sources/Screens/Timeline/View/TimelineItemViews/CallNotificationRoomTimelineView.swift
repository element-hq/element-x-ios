//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import Foundation
import SwiftUI

struct CallNotificationRoomTimelineView: View {
    @Environment(\.timelineContext) private var context
    
    let timelineItem: CallNotificationRoomTimelineItem
    
    var body: some View {
        let tileTitle = if timelineItem.isDM {
            // As per design only have declined variants in DM
            if timelineItem.isDeclinedByMe {
                L10n.commonCallYouDeclined
            } else if timelineItem.isDeclined {
                L10n.commonCallDeclined
            } else {
                L10n.commonCallStarted
            }
        } else {
            L10n.commonCallStarted
        }
        
        let iconKeyPath: KeyPath<CompoundIcons, Image> = if timelineItem.isDM, timelineItem.isDeclined || timelineItem.isDeclinedByMe {
            // As per design only have declined variants in DM
            timelineItem.isVoiceCall ? \.voiceCallDeclinedSolid : \.videoCallDeclinedSolid
        } else {
            timelineItem.isVoiceCall ? \.voiceCallSolid : \.videoCallSolid
        }

        HStack(spacing: 12) {
            CompoundIcon(iconKeyPath, size: .medium, relativeTo: .compound.headingMDBold)
                .foregroundStyle(.compound.iconSecondary)
                .accessibilityHidden(true)
              
            Text(tileTitle)
                .font(.compound.bodyMD)
                .foregroundColor(.compound.textSecondary)
                .labelStyle(.custom(spacing: 4))

            Spacer()

            Text(timelineItem.timestamp.formattedTime())
                .font(.compound.bodyXS)
                .foregroundColor(.compound.textSecondary)
        }
        .padding(12)
        .overlay(RoundedRectangle(cornerRadius: 8)
            .stroke(.compound.borderInteractiveSecondary, lineWidth: 1))
        .padding(16)
    }
}

struct CallNotificationRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(spacing: 0) {
            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isEditable: false,
                                                                 canBeRepliedTo: false,
                                                                 isDM: false,
                                                                 isDeclinedByMe: false,
                                                                 isDeclined: false,
                                                                 isVoiceCall: false))

            Divider()

            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isEditable: false,
                                                                 canBeRepliedTo: false,
                                                                 isDM: true,
                                                                 isDeclinedByMe: false,
                                                                 isDeclined: false,
                                                                 isVoiceCall: true))

            Divider()

            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isEditable: false,
                                                                 canBeRepliedTo: false,
                                                                 isDM: false,
                                                                 isDeclinedByMe: true,
                                                                 isDeclined: true,
                                                                 isVoiceCall: false))

            Divider()

            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isEditable: false,
                                                                 canBeRepliedTo: false,
                                                                 isDM: true,
                                                                 isDeclinedByMe: false,
                                                                 isDeclined: true,
                                                                 isVoiceCall: true))

            Divider()

            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isEditable: false,
                                                                 canBeRepliedTo: false,
                                                                 isDM: true,
                                                                 isDeclinedByMe: true,
                                                                 isDeclined: true,
                                                                 isVoiceCall: true))

            Divider()

            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isEditable: false,
                                                                 canBeRepliedTo: false,
                                                                 isDM: true,
                                                                 isDeclinedByMe: false,
                                                                 isDeclined: true,
                                                                 isVoiceCall: false))

            Divider()

            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isEditable: false,
                                                                 canBeRepliedTo: false,
                                                                 isDM: true,
                                                                 isDeclinedByMe: true,
                                                                 isDeclined: true,
                                                                 isVoiceCall: false))

            Divider()
        }
        .padding()
    }
}
