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
import Foundation
import SwiftUI

struct VoiceMessagePreviewComposer: View {
    @ObservedObject var playerState: AudioPlayerState
    let waveform: WaveformSource
    @ScaledMetric private var waveformLineWidth = 2.0
    @ScaledMetric private var waveformLinePadding = 2.0
    @State private var resumePlaybackAfterScrubbing = false

    let onPlay: () -> Void
    let onPause: () -> Void
    let onSeek: (Double) -> Void

    @State var dragState: WaveformViewDragState = .inactive
    @State private var tappedProgress: CGFloat = 0

    private static let elapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm:ss"
        return dateFormatter
    }()
        
    var timeLabelContent: String {
        // Display the duration if progress is 0.0
        let percent = playerState.progress > 0.0 ? playerState.progress : 1.0
        // If the duration is greater or equal 10 minutes, use the long format
        let elapsed = Date(timeIntervalSinceReferenceDate: playerState.duration * percent)
        return Self.elapsedTimeFormatter.string(from: elapsed)
    }
    
    var showWaveformCursor: Bool {
        playerState.playbackState == .playing || dragState.isActive
    }
            
    var body: some View {
        HStack {
            HStack {
                VoiceMessageButton(state: .init(state: playerState.playbackState),
                                   size: .small,
                                   action: onPlayPause)
                Text(timeLabelContent)
                    .lineLimit(1)
                    .font(.compound.bodySMSemibold)
                    .foregroundColor(.compound.textSecondary)
                    .monospacedDigit()
                    .fixedSize(horizontal: true, vertical: true)
            }
            waveformView
                .progressTapGesture(progress: $tappedProgress)
                .progressCursor(progress: playerState.progress) {
                    WaveformCursorView(color: .compound.iconAccentTertiary)
                        .opacity(showWaveformCursor ? 1 : 0)
                        .frame(width: waveformLineWidth)
                }
                .onChange(of: dragState) { dragState in
                    switch dragState {
                    case .inactive:
                        onScrubbing(false)
                    case .pressing(let progress):
                        onScrubbing(true)
                        onSeek(max(0, min(progress, 1.0)))
                    case .dragging(let progress):
                        onSeek(max(0, min(progress, 1.0)))
                    }
                    self.dragState = dragState
                }
        }
        .padding(.vertical, 4.0)
        .padding(.horizontal, 6.0)
        .background {
            let roundedRectangle = RoundedRectangle(cornerRadius: 12)
            ZStack {
                roundedRectangle
                    .fill(Color.compound.bgSubtleSecondary)
            }
        }
        .frame(minHeight: 42)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder
    private var waveformView: some View {
        let configuration: Waveform.Configuration = .init(style: .striped(.init(color: .black, width: waveformLineWidth, spacing: waveformLinePadding)),
                                                          verticalScalingFactor: 1.0)
        switch waveform {
        case .url(let url):
            WaveformView(audioURL: url,
                         configuration: configuration)
                .progressMask(progress: playerState.progress)
        case .data(let array):
            WaveformLiveCanvas(samples: array,
                               configuration: configuration)
                .progressMask(progress: playerState.progress)
        }
    }

    private func onPlayPause() {
        if playerState.playbackState == .playing {
            onPause()
        } else {
            onPlay()
        }
    }
    
    private func onScrubbing(_ scrubbing: Bool) {
        if scrubbing {
            if playerState.playbackState == .playing {
                resumePlaybackAfterScrubbing = true
                onPause()
            }
        } else {
            if resumePlaybackAfterScrubbing {
                onPlay()
                resumePlaybackAfterScrubbing = false
            }
        }
    }
}

struct VoiceMessagePreviewComposer_Previews: PreviewProvider, TestablePreview {
    static let playerState = AudioPlayerState(id: .recorderPreview,
                                              duration: 10.0,
                                              waveform: EstimatedWaveform.mockWaveform,
                                              progress: 0.4)
    
    static let waveformData: [Float] = Array(repeating: 1.0, count: 1000)
    
    static var previews: some View {
        VStack {
            VoiceMessagePreviewComposer(playerState: playerState, waveform: .data(waveformData), onPlay: { }, onPause: { }, onSeek: { _ in })
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
