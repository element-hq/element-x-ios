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

import DSWaveformImage
import DSWaveformImageViews
import SwiftUI

struct VoiceMessageRoomPlaybackView: View {
    @ObservedObject var playerState: AudioPlayerState
    @ScaledMetric private var waveformLineWidth = 2.0
    @ScaledMetric private var waveformLinePadding = 2.0
    @GestureState var isDragging = false

    let onPlayPause: () -> Void
    let onSeek: (Double) -> Void
    let onScrubbing: (Bool) -> Void

    var timeLabelContent: String {
        // Display the duration if progress is 0.0
        let percent = playerState.progress > 0.0 ? playerState.progress : 1.0
        // If the duration is greater or equal 10 minutes, use the long format
        let elapsed = Date(timeIntervalSinceReferenceDate: playerState.duration * percent)
        if playerState.duration >= 600 {
            return DateFormatter.longElapsedTimeFormatter.string(from: elapsed)
        } else {
            return DateFormatter.elapsedTimeFormatter.string(from: elapsed)
        }
    }
    
    var showWaveformCursor: Bool {
        playerState.playbackState == .playing || isDragging
    }
    
    var body: some View {
        HStack {
            HStack {
                VoiceMessageButton(state: .init(state: playerState.playbackState),
                                   size: .medium,
                                   action: onPlayPause)
                Text(timeLabelContent)
                    .lineLimit(1)
                    .font(.compound.bodySMSemibold)
                    .foregroundColor(.compound.textSecondary)
                    .monospacedDigit()
                    .fixedSize(horizontal: true, vertical: true)
            }

            waveformView
                .waveformInteraction(isDragging: $isDragging,
                                     progress: playerState.progress,
                                     showCursor: showWaveformCursor,
                                     onSeek: onSeek)
        }
        .padding(.leading, 2)
        .padding(.trailing, 8)
        .onChange(of: isDragging) { isDragging in
            onScrubbing(isDragging)
        }
    }

    @ViewBuilder
    private var waveformView: some View {
        if let url = playerState.fileURL {
            WaveformView(audioURL: url,
                         configuration: .init(style: .striped(.init(color: .black, width: waveformLineWidth, spacing: waveformLinePadding)),
                                              verticalScalingFactor: 1.0),
                         placeholder: { estimatedWaveformView })
                .progressMask(progress: playerState.progress)
        } else {
            estimatedWaveformView
        }
    }

    private var estimatedWaveformView: some View {
        EstimatedWaveformView(lineWidth: waveformLineWidth,
                              linePadding: waveformLinePadding,
                              waveform: playerState.waveform,
                              progress: playerState.progress)
    }
}

private extension DateFormatter {
    static let elapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "m:ss"
        return dateFormatter
    }()

    static let longElapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm:ss"
        return dateFormatter
    }()
}

struct VoiceMessageRoomPlaybackView_Previews: PreviewProvider, TestablePreview {
    static let waveform = EstimatedWaveform(data: [3, 127, 400, 266, 126, 122, 373, 251, 45, 112,
                                                   334, 205, 99, 138, 397, 354, 125, 361, 199, 51,
                                                   294, 131, 19, 2, 3, 3, 1, 2, 0, 0,
                                                   0, 0, 0, 0, 0, 3])
    
    static var playerState = AudioPlayerState(id: .timelineItemIdentifier(.random),
                                              duration: 10.0,
                                              waveform: waveform,
                                              progress: 0.3)
    
    static var previews: some View {
        VoiceMessageRoomPlaybackView(playerState: playerState,
                                     onPlayPause: { },
                                     onSeek: { value in Task { await playerState.updateState(progress: value) } },
                                     onScrubbing: { _ in })
            .fixedSize(horizontal: false, vertical: true)
    }
}
