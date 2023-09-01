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

import SwiftUI

struct VoiceMessagePlaybackData {
    let currentTime: String
    let progress: Float
    let waveform: Waveform
    let playing: Bool
    let playingEnabled: Bool
    let recording: Bool
}

enum PlaybackState: Equatable {
    case disabled
    case paused
    case playing
    case recording
}

extension VoiceMessagePlaybackData {
    static let mockPlaybackData = VoiceMessagePlaybackData(currentTime: "1:23",
                                                           progress: 0.6,
                                                           waveform: Waveform.mockWaveform,
                                                           playing: true,
                                                           playingEnabled: true,
                                                           recording: false)
}

struct VoiceMessagePlaybackView: View {
    let playbackData: VoiceMessagePlaybackData
    let didTogglePlayPause: (Bool) -> Void
    
    var body: some View {
        HStack {
            playPauseButton
            Text(playbackData.currentTime)
                .font(.compound.bodySMSemibold)
                .foregroundColor(.compound.textSecondary)
                .padding(.trailing, 7)
            WaveformView(waveform: playbackData.waveform)
                .frame(width: 150, height: 34)
        }
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
    }
    
    var playPauseButton: some View {
        Button {
            didTogglePlayPause(!playbackData.playing)
        } label: {
            Image(systemName: playbackData.playing ? "pause.fill" : "play.fill")
                .foregroundColor(.compound.iconSecondary)
                .background(
                    Circle()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.compound.bgCanvasDefault)
                )
                .padding(.trailing, 7)
        }
    }
}

struct VoiceMessagePlaybackView_Previews: PreviewProvider {
    static var previews: some View {
        VoiceMessagePlaybackView(playbackData: VoiceMessagePlaybackData.mockPlaybackData, didTogglePlayPause: { _ in })
    }
}
