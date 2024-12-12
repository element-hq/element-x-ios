//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation
import SwiftUI

struct VoiceMessageRoomTimelineView: View {
    let timelineItem: VoiceMessageRoomTimelineItem
    let playerState: AudioPlayerState
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VoiceMessageRoomTimelineContent(timelineItem: timelineItem,
                                            playerState: playerState)
                .accessibilityLabel(L10n.commonVoiceMessage)
                .frame(maxWidth: 400)
        }
    }
}

struct VoiceMessageRoomTimelineContent: View {
    @Environment(\.timelineContext) private var context
    @State private var resumePlaybackAfterScrubbing = false
    
    let timelineItem: VoiceMessageRoomTimelineItem
    let playerState: AudioPlayerState
    
    var body: some View {
        VoiceMessageRoomPlaybackView(playerState: playerState,
                                     onPlayPause: onPlaybackPlayPause,
                                     onSeek: { onPlaybackSeek($0) },
                                     onScrubbing: { onPlaybackScrubbing($0) })
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func onPlaybackPlayPause() {
        context?.send(viewAction: .handleAudioPlayerAction(.playPause(itemID: timelineItem.id)))
    }
    
    private func onPlaybackSeek(_ progress: Double) {
        context?.send(viewAction: .handleAudioPlayerAction(.seek(itemID: timelineItem.id, progress: progress)))
    }
    
    private func onPlaybackScrubbing(_ dragging: Bool) {
        if dragging {
            if playerState.playbackState == .playing {
                resumePlaybackAfterScrubbing = true
                context?.send(viewAction: .handleAudioPlayerAction(.playPause(itemID: timelineItem.id)))
            }
        } else {
            if resumePlaybackAfterScrubbing {
                context?.send(viewAction: .handleAudioPlayerAction(.playPause(itemID: timelineItem.id)))
                resumePlaybackAfterScrubbing = false
            }
        }
    }
}

struct VoiceMessageRoomTimelineView_Previews: PreviewProvider, TestablePreview {
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
        body.environmentObject(viewModel.context)
    }
    
    static var body: some View {
        VoiceMessageRoomTimelineView(timelineItem: voiceRoomTimelineItem, playerState: playerState)
            .fixedSize(horizontal: false, vertical: true)
    }
}
