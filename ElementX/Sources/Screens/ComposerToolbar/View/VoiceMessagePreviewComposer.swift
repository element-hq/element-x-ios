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
    @ScaledMetric private var waveformLineWidth = 2.0
    @ScaledMetric private var waveformLinePadding = 2.0
    @State private var resumePlaybackAfterScrubbing = false

    let onPlay: () -> Void
    let onPause: () -> Void
    let onSeek: (Double) -> Void
    
    @ScaledMetric private var playPauseButtonSize = 32
    @ScaledMetric private var playPauseImagePadding = 8
    @State var dragState: WaveformViewDragState = .inactive
    
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
        playerState.playbackState == .playing || dragState.isDragging
    }
        
    var body: some View {
        HStack {
            HStack {
                playPauseButton
                Text(timeLabelContent)
                    .lineLimit(1)
                    .font(.compound.bodySMSemibold)
                    .foregroundColor(.compound.textSecondary)
                    .monospacedDigit()
                    .fixedSize(horizontal: true, vertical: true)
            }
            WaveformView(lineWidth: waveformLineWidth, linePadding: waveformLinePadding, waveform: playerState.waveform, progress: playerState.progress, showCursor: showWaveformCursor)
                .dragGesture($dragState)
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
                roundedRectangle
                    .stroke(Color.compound._borderTextFieldFocused, lineWidth: 0.5)
            }
        }
        .frame(minHeight: 42)
        .fixedSize(horizontal: false, vertical: true)
    }
    
    @ViewBuilder
    private var playPauseButton: some View {
        Button {
            onPlayPause()
        } label: {
            ZStack {
                Circle()
                    .foregroundColor(.compound.bgCanvasDefault)
                if playerState.playbackState == .loading {
                    ProgressView()
                } else {
                    Image(asset: playerState.playbackState == .playing ? Asset.Images.mediaPause : Asset.Images.mediaPlay)
                        .resizable()
                        .padding(playPauseImagePadding)
                        .offset(x: playerState.playbackState == .playing ? 0 : 2)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.compound.iconSecondary)
                        .accessibilityLabel(playerState.playbackState == .playing ? L10n.a11yPause : L10n.a11yPlay)
                }
            }
        }
        .disabled(playerState.playbackState == .loading)
        .frame(width: playPauseButtonSize,
               height: playPauseButtonSize)
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
    static let playerState = AudioPlayerState(duration: 10.0,
                                              waveform: EstimatedWaveform.mockWaveform,
                                              progress: 0.4)
    
    static var previews: some View {
        VStack {
            VoiceMessagePreviewComposer(playerState: playerState, onPlay: { }, onPause: { }, onSeek: { _ in })
                .fixedSize(horizontal: false, vertical: true)
        }
    }
}
