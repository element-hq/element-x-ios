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

struct VoiceMessagePreviewComposer: View {
    @ObservedObject var playerState: AudioPlayerState
    
    @State private var resumePlaybackAfterScrubbing = false
    
    var body: some View {
        VoiceMessageRoomPlaybackView(playerState: playerState,
                                     waveformMaxWidth: 0,
                                     onPlayPause: onPlaybackPlayPause,
                                     onSeek: { onPlaybackSeek($0) },
                                     onScrubbing: { onPlaybackScrubbing($0) })
            .padding(.vertical, 4.0)
            .padding(.horizontal, 6.0)
            .background {
                let roundedRectangle = RoundedRectangle(cornerRadius: 12)
                ZStack {
                    roundedRectangle
                        .fill(Color.compound.bgSubtleSecondary)
                    roundedRectangle
                        .stroke(Color.compound._borderTextFieldFocused, lineWidth: 0.5)
                }
            }
            .frame(minHeight: 42)
            .fixedSize(horizontal: false, vertical: true)
    }
    
    private func onPlaybackPlayPause() { }
    
    private func onPlaybackSeek(_ progress: Double) { }
    
    private func onPlaybackScrubbing(_ dragging: Bool) { }
}

struct VoiceMessagePreviewComposer_Previews: PreviewProvider, TestablePreview {
    static let playerState = AudioPlayerState(duration: 10.0,
                                              waveform: Waveform.mockWaveform,
                                              progress: 0.4)
    
    static var previews: some View {
        VStack {
            VoiceMessagePreviewComposer(playerState: playerState)
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
