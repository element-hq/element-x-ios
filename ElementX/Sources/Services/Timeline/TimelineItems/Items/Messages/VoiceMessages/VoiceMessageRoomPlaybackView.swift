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

    let onPlayPause: () -> Void
    let onSeek: (Double) -> Void
    let onScrubbing: (Bool) -> Void

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @State private var sendFeedback = false
        
    @ScaledMetric private var playPauseButtonSize = 32
    @ScaledMetric private var playPauseImagePadding = 8
    
    private static let elapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "m:ss"
        return dateFormatter
    }()
    
    private static let longElapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm:ss"
        return dateFormatter
    }()
        
    @State var dragState: WaveformViewDragState = .inactive
    
    var timeLabelContent: String {
        // Display the duration if progress is 0.0
        let percent = playerState.progress > 0.0 ? playerState.progress : 1.0
        // If the duration is greater or equal 10 minutes, use the long format
        let elapsed = Date(timeIntervalSinceReferenceDate: playerState.duration * percent)
        if playerState.duration >= 600 {
            return Self.longElapsedTimeFormatter.string(from: elapsed)
        } else {
            return Self.elapsedTimeFormatter.string(from: elapsed)
        }
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
            waveformView
                .waveformDragGesture($dragState)
                .progressCursor(progress: playerState.progress) {
                    WaveformCursorView(color: .compound.iconAccentTertiary)
                        .opacity(showWaveformCursor ? 1 : 0)
                        .frame(width: waveformLineWidth)
                }
        }
        .onChange(of: dragState) { newDragState in
            switch newDragState {
            case .inactive:
                onScrubbing(false)
            case .pressing:
                onScrubbing(true)
                feedbackGenerator.prepare()
                sendFeedback = true
            case .dragging(let progress):
                if sendFeedback {
                    feedbackGenerator.impactOccurred()
                    sendFeedback = false
                }
                onSeek(max(0, min(progress, 1.0)))
            }
        }
        .padding(.leading, 2)
        .padding(.trailing, 8)
    }
    
    @ViewBuilder
    var playPauseButton: some View {
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

private enum DragState: Equatable {
    case inactive
    case pressing(progress: Double)
    case dragging(progress: Double)
    
    var progress: Double {
        switch self {
        case .inactive, .pressing:
            return .zero
        case .dragging(let progress):
            return progress
        }
    }
    
    var isActive: Bool {
        switch self {
        case .inactive:
            return false
        case .pressing, .dragging:
            return true
        }
    }
    
    var isDragging: Bool {
        switch self {
        case .inactive, .pressing:
            return false
        case .dragging:
            return true
        }
    }
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
