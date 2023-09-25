//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation
import SwiftUI

struct VoiceRoomTimelineView: View {
    @EnvironmentObject private var context: RoomScreenViewModel.Context
    let timelineItem: VoiceRoomTimelineItem
    let playerState: AudioPlayerState
    @State var resumePlaybackAfterScrubbing = false
    
    init(timelineItem: VoiceRoomTimelineItem, playerState: AudioPlayerState?) {
        self.timelineItem = timelineItem
        self.playerState = playerState ?? AudioPlayerState(duration: 0)
    }
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VoiceRoomPlaybackView(playerState: playerState,
                                  onPlayPause: onPlaybackPlayPause,
                                  onSeek: onPlaybackSeek(_:),
                                  onScrubbing: onPlaybackScrubbing(_:))
                .fixedSize(horizontal: false, vertical: true)
        }
    }
    
    private func onPlaybackPlayPause() {
        context.send(viewAction: .playPauseAudio(itemID: timelineItem.id))
    }
    
    private func onPlaybackSeek(_ progress: Double) {
        context.send(viewAction: .seekAudio(itemID: timelineItem.id, progress: progress))
    }
    
    private func onPlaybackScrubbing(_ dragging: Bool) {
        if dragging {
            if playerState.playing {
                resumePlaybackAfterScrubbing = true
                context.send(viewAction: .playPauseAudio(itemID: timelineItem.id))
            }
            context.send(viewAction: .disableLongPress(itemID: timelineItem.id))
        } else {
            context.send(viewAction: .enableLongPress(itemID: timelineItem.id))
            if resumePlaybackAfterScrubbing {
                context.send(viewAction: .playPauseAudio(itemID: timelineItem.id))
                resumePlaybackAfterScrubbing = false
            }
        }
    }
}

struct VoiceRoomTimelineView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = RoomScreenViewModel.mock

    static let voiceRoomTimelineItem = VoiceRoomTimelineItem(id: .random,
                                                             timestamp: "Now",
                                                             isOutgoing: false,
                                                             isEditable: false,
                                                             canBeRepliedTo: true,
                                                             isThreaded: false,
                                                             sender: .init(id: "Bob"),
                                                             content: .init(body: "audio.ogg",
                                                                            duration: 300,
                                                                            waveform: Waveform.mockWaveform,
                                                                            source: nil,
                                                                            contentType: nil))
    
    static let playerState = AudioPlayerState(duration: 10.0,
                                              waveform: Waveform.mockWaveform,
                                              progress: 0.4)
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
            .previewDisplayName("Bubble")
        body
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
            .previewDisplayName("Plain")
    }
    
    static var body: some View {
        VoiceRoomTimelineView(timelineItem: voiceRoomTimelineItem, playerState: playerState)
            .fixedSize(horizontal: false, vertical: true)
    }
}
