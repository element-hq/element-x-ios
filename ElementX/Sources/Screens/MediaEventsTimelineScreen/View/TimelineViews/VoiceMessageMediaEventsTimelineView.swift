//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct VoiceMessageMediaEventsTimelineView: View {
    let timelineItem: VoiceMessageRoomTimelineItem
    let playerState: AudioPlayerState
    
    var body: some View {
        VoiceMessageRoomTimelineContent(timelineItem: timelineItem,
                                        playerState: playerState)
            .accessibilityLabel(L10n.commonVoiceMessage)
            .frame(maxWidth: .infinity, alignment: .leading)
            .bubbleBackground(isOutgoing: timelineItem.isOutgoing)
    }
}

// MARK: - Content

struct VoiceMessageMediaEventsTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = TimelineViewModel.mock
    static let timelineItemIdentifier = TimelineItemIdentifier.randomEvent
    static let voiceRoomTimelineItem = VoiceMessageRoomTimelineItem(id: timelineItemIdentifier,
                                                                    timestamp: .mock,
                                                                    isOutgoing: false,
                                                                    isEditable: false,
                                                                    canBeRepliedTo: true,
                                                                    isThreaded: false,
                                                                    sender: .init(id: "Bob"),
                                                                    content: .init(filename: "audio.ogg",
                                                                                   duration: 300,
                                                                                   waveform: EstimatedWaveform.mockWaveform,
                                                                                   source: nil,
                                                                                   fileSize: nil,
                                                                                   contentType: nil))
    
    static let playerState = AudioPlayerState(id: .timelineItemIdentifier(timelineItemIdentifier),
                                              title: L10n.commonVoiceMessage,
                                              duration: 10.0,
                                              waveform: EstimatedWaveform.mockWaveform,
                                              progress: 0.4)
    
    static var previews: some View {
        body
            .environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VoiceMessageMediaEventsTimelineView(timelineItem: voiceRoomTimelineItem, playerState: playerState)
            .fixedSize(horizontal: false, vertical: true)
    }
}
