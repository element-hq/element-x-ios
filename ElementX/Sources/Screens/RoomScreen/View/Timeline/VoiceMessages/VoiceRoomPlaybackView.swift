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

struct VoiceRoomPlaybackView: View {
    @ObservedObject var playbackData: VoiceRoomPlaybackData
    
    let waveformMaxWidth: CGFloat = 150
    let playPauseButtonSize = CGSize(width: 32, height: 32)
    
    private static let elapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "m:ss"
        return dateFormatter
    }()
    
    var onPlayPause: () -> Void = { }
    var onSeek: (Double) -> Void = { _ in }
    
    var body: some View {
        HStack {
            HStack {
                playPauseButton
                Text(Self.elapsedTimeFormatter.string(from: Date(timeIntervalSinceReferenceDate: playbackData.duration * playbackData.progress)))
                    .font(.compound.bodySMSemibold)
                    .foregroundColor(.compound.textSecondary)
                    .monospacedDigit()
            }
            .padding(.vertical, 6)
            GeometryReader { geometry in
                WaveformView(waveform: playbackData.waveform, progress: playbackData.progress)
                    .gesture(DragGesture(minimumDistance: 10, coordinateSpace: .local)
                        .onChanged { value in
                            let position = value.location.x / geometry.size.width
                            if abs(position - playbackData.progress) > 0.01 {
                                onSeek(max(0, min(position, 1.0)))
                            }
                        }
                        .onEnded { value in
                            let position = value.location.x / geometry.size.width
                            onSeek(max(0, min(position, 1.0)))
                        }
                    )
                    .transaction { transaction in
                        // Disable animation
                        transaction.animation = nil
                    }
            }
            .frame(maxWidth: waveformMaxWidth)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder
    var playPauseButton: some View {
        Button {
            onPlayPause()
        } label: {
            Image(systemName: playbackData.playing ? "pause.fill" : "play.fill")
                .foregroundColor(.compound.iconSecondary)
                .background(
                    Circle()
                        .frame(width: playPauseButtonSize.width,
                               height: playPauseButtonSize.height)
                        .foregroundColor(.compound.bgCanvasDefault)
                )
                .padding(.trailing, 7)
        }
    }
}

struct VoiceRoomPlaybackView_Previews: PreviewProvider {
    static let waveform = Waveform(data: [3, 127, 400, 266, 126, 122, 373, 251, 45, 112,
                                          334, 205, 99, 138, 397, 354, 125, 361, 199, 51,
                                          294, 131, 19, 2, 3, 3, 1, 2, 0, 0,
                                          0, 0, 0, 0, 0, 3])
    
    static let playbackData = VoiceRoomPlaybackData(duration: 10.0,
                                                    waveform: waveform,
                                                    progress: 2.0,
                                                    playing: false)
    
    static var previews: some View {
        VoiceRoomPlaybackView(playbackData: playbackData)
            .fixedSize(horizontal: false, vertical: true)
    }
}
