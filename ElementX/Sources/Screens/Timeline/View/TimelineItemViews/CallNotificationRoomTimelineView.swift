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
    
    private var tileTitle: String {
        var title = L10n.commonCallStarted
        if timelineItem.isDM {
            // We only have declined variants in DM
            if timelineItem.isDeclinedByMe {
                title = L10n.commonCallYouDeclined
            } else if timelineItem.isDeclined {
                title = L10n.commonCallDeclined
            }
        }
        return title
    }
    
    private var iconKeyPath: KeyPath<CompoundIcons, Image> {
        if timelineItem.isDM {
            // We only have declined variants in DM
            if timelineItem.isDeclined || timelineItem.isDeclinedByMe {
                return timelineItem.isVoiceCall ? \.voiceCallDeclinedSolid : \.videoCallDeclinedSolid
            }
        }
        return timelineItem.isVoiceCall ? \.voiceCallSolid : \.videoCallSolid
    }
    
    var body: some View {
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
        ScrollView {
            VStack(spacing: 0) {
                CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                     timestamp: .mock,
                                                                     isEditable: false,
                                                                     canBeRepliedTo: false,
                                                                     isDM: false,
                                                                     isDeclinedByMe: false,
                                                                     isDeclined: false,
                                                                     isVoiceCall: false))
                    .previewDisplayName("Video call started")

                Divider()

                CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                     timestamp: .mock,
                                                                     isEditable: false,
                                                                     canBeRepliedTo: false,
                                                                     isDM: true,
                                                                     isDeclinedByMe: false,
                                                                     isDeclined: false,
                                                                     isVoiceCall: true))
                    .previewDisplayName("Voice call started")

                Divider()

                CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                     timestamp: .mock,
                                                                     isEditable: false,
                                                                     canBeRepliedTo: false,
                                                                     isDM: false,
                                                                     isDeclinedByMe: true,
                                                                     isDeclined: true,
                                                                     isVoiceCall: false))
                    .previewDisplayName("Room • Call declined is not shown")

                Divider()

                CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                     timestamp: .mock,
                                                                     isEditable: false,
                                                                     canBeRepliedTo: false,
                                                                     isDM: true,
                                                                     isDeclinedByMe: false,
                                                                     isDeclined: true,
                                                                     isVoiceCall: true))
                    .previewDisplayName("DM • Voice call declined")

                Divider()

                CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                     timestamp: .mock,
                                                                     isEditable: false,
                                                                     canBeRepliedTo: false,
                                                                     isDM: true,
                                                                     isDeclinedByMe: true,
                                                                     isDeclined: true,
                                                                     isVoiceCall: true))
                    .previewDisplayName("DM • Voice Declined by me")

                Divider()

                CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                     timestamp: .mock,
                                                                     isEditable: false,
                                                                     canBeRepliedTo: false,
                                                                     isDM: true,
                                                                     isDeclinedByMe: false,
                                                                     isDeclined: true,
                                                                     isVoiceCall: false))
                    .previewDisplayName("Dm • Video • Call Declined")

                Divider()

                CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                     timestamp: .mock,
                                                                     isEditable: false,
                                                                     canBeRepliedTo: false,
                                                                     isDM: true,
                                                                     isDeclinedByMe: true,
                                                                     isDeclined: true,
                                                                     isVoiceCall: false))
                    .previewDisplayName("DM • Video • Declined by me")

                Divider()
            }
            .padding()
        }
    }
}
