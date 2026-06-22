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
    let timelineItem: CallNotificationRoomTimelineItem
    
    var body: some View {
        switch timelineItem.callState {
        case .tombstoned(let isDeclinedByMe, let isDeclined):
            tombstonedCallView(isDeclinedByMe: isDeclinedByMe, isDeclined: isDeclined)
        case .active(let activeMembers, let isJoined, let callStartTimestamp):
            ActiveCallTimelineItemView(isDM: timelineItem.isDM,
                                       isVoiceCall: timelineItem.isVoiceCall,
                                       activeMembers: activeMembers,
                                       sender: timelineItem.sender,
                                       isJoined: isJoined,
                                       callStartTimestamp: callStartTimestamp)
        }
    }
    
    // MARK: - Tombstoned Call View
    
    private func tombstonedCallView(isDeclinedByMe: Bool, isDeclined: Bool) -> some View {
        HStack(spacing: 12) {
            CompoundIcon(iconKeyPath(isDeclinedByMe: isDeclinedByMe, isDeclined: isDeclined), size: .medium, relativeTo: .compound.headingMDBold)
                .foregroundStyle(.compound.iconSecondary)
                .accessibilityHidden(true)
            
            Text(tileTitle(isDeclinedByMe: isDeclinedByMe, isDeclined: isDeclined))
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
    
    // MARK: - Private
    
    private func tileTitle(isDeclinedByMe: Bool, isDeclined: Bool) -> String {
        if timelineItem.isDM {
            // As per design only have declined variants in DM
            if isDeclinedByMe {
                L10n.commonCallYouDeclined
            } else if isDeclined {
                L10n.commonCallDeclined
            } else {
                L10n.commonCallStarted
            }
        } else {
            L10n.commonCallStarted
        }
    }
    
    private func iconKeyPath(isDeclinedByMe: Bool, isDeclined: Bool) -> KeyPath<CompoundIcons, Image> {
        if timelineItem.isDM, isDeclined || isDeclinedByMe {
            // As per design only have declined variants in DM
            timelineItem.isVoiceCall ? \.voiceCallDeclinedSolid : \.videoCallDeclinedSolid
        } else {
            timelineItem.isVoiceCall ? \.voiceCallSolid : \.videoCallSolid
        }
    }
}

struct CallNotificationRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VStack(spacing: 0) {
            // Tombstoned call previews
            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isDM: false,
                                                                 isVoiceCall: false,
                                                                 callState: .tombstoned(isDeclinedByMe: false, isDeclined: false)))
            
            Divider()
            
            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isDM: true,
                                                                 isVoiceCall: true,
                                                                 callState: .tombstoned(isDeclinedByMe: false, isDeclined: false)))
            
            Divider()
            
            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isDM: false,
                                                                 isVoiceCall: false,
                                                                 callState: .tombstoned(isDeclinedByMe: true, isDeclined: true)))
            
            Divider()
            
            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isDM: true,
                                                                 isVoiceCall: true,
                                                                 callState: .tombstoned(isDeclinedByMe: false, isDeclined: true)))
            
            Divider()
            
            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isDM: true,
                                                                 isVoiceCall: false,
                                                                 callState: .tombstoned(isDeclinedByMe: false, isDeclined: true)))
            
            Divider()
            
            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isDM: true,
                                                                 isVoiceCall: false,
                                                                 callState: .tombstoned(isDeclinedByMe: true, isDeclined: true)))
            
            Divider()
            
            // Active call previews
            CallNotificationRoomTimelineView(timelineItem: .init(id: .randomEvent,
                                                                 timestamp: .mock,
                                                                 isDM: false,
                                                                 isVoiceCall: false,
                                                                 callState: .active(activeMembers: ["@alice:example.org"],
                                                                                    isJoined: false,
                                                                                    callStartTimestamp: Date())))
        }
        .padding()
    }
}
