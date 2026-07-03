//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
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
        ContentScanningView(contentScannerService: context?.contentScannerService,
                            mediaSource: timelineItem.content.source) {
            VoiceMessageRoomPlaybackView(playerState: playerState,
                                         onPlayPause: onPlaybackPlayPause,
                                         onSeek: { onPlaybackSeek($0) },
                                         onScrubbing: { onPlaybackScrubbing($0) },
                                         onPlaybackSpeedChange: onPlaybackSpeedChange)
                .fixedSize(horizontal: false, vertical: true)
        } loading: {
            VoiceMessageRoomPlaybackView(playerState: playerState,
                                         isScanning: true,
                                         onPlayPause: { },
                                         onSeek: { _ in },
                                         onScrubbing: { _ in },
                                         onPlaybackSpeedChange: { })
                .fixedSize(horizontal: false, vertical: true)
        } failed: { failure in
            ContentScanningFailureView(failure: failure)
        }
    }
    
    private func onPlaybackPlayPause() {
        context?.send(viewAction: .handleAudioPlayerAction(.playPause(itemID: timelineItem.id)))
    }
    
    private func onPlaybackSpeedChange() {
        context?.send(viewAction: .handleAudioPlayerAction(.changePlaybackSpeed(itemID: timelineItem.id)))
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
    static let scanningViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(scanResult: nil)))
    static let unsafeViewModel = TimelineViewModel.mock(contentScannerService: ContentScannerServiceMock(.init(scanResult: false)))
    static let timelineItemIdentifier = TimelineItemIdentifier.randomEvent
    static let voiceRoomTimelineItem = VoiceMessageRoomTimelineItem(id: timelineItemIdentifier,
                                                                    timestamp: .mock,
                                                                    isOutgoing: false,
                                                                    isEditable: false,
                                                                    canBeRepliedTo: true,
                                                                    sender: .init(id: "Bob"),
                                                                    content: .init(filename: "audio.ogg",
                                                                                   duration: 300,
                                                                                   waveform: EstimatedWaveform.mockWaveform,
                                                                                   source: try? MediaSourceProxy(url: .mockMXCAudio, mimeType: nil),
                                                                                   fileSize: nil,
                                                                                   contentType: nil))
    
    static let playerState = AudioPlayerState(id: .timelineItemIdentifier(timelineItemIdentifier),
                                              title: L10n.commonVoiceMessage,
                                              duration: 10.0,
                                              waveform: EstimatedWaveform.mockWaveform,
                                              progress: 0.4)
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
        
        VStack(spacing: 20) {
            VoiceMessageRoomTimelineView(timelineItem: voiceRoomTimelineItem, playerState: playerState)
                .environmentObject(scanningViewModel.context)
                .environment(\.timelineContext, scanningViewModel.context)
            
            VoiceMessageRoomTimelineView(timelineItem: voiceRoomTimelineItem, playerState: playerState)
                .environmentObject(unsafeViewModel.context)
                .environment(\.timelineContext, unsafeViewModel.context)
        }
        .fixedSize(horizontal: false, vertical: true)
        .environmentObject(viewModel.context)
        .previewDisplayName("Content Scanner")
    }
    
    static var body: some View {
        VoiceMessageRoomTimelineView(timelineItem: voiceRoomTimelineItem, playerState: playerState)
            .fixedSize(horizontal: false, vertical: true)
    }
}
