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

struct VoiceMessageRoomPlaybackView: View {
    @ObservedObject var playerState: AudioPlayerState
    let onPlayPause: () -> Void
    let onSeek: (Double) -> Void
    let onScrubbing: (Bool) -> Void

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @State private var sendFeedback = false
    
    @ScaledMetric private var waveformLineWidth = 2.0
    @ScaledMetric private var waveformLinePadding = 2.0
    private let waveformMaxWidth: CGFloat = 150
    private let playPauseButtonSize = CGSize(width: 32, height: 32)
    
    private static let elapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "m:ss"
        return dateFormatter
    }()
        
    @GestureState private var dragState = DragState.inactive
    @State private var tapProgress: Double = .zero
    
    var timeLabelContent: String {
        // Display the duration if progress is 0.0
        let percent = playerState.progress > 0.0 ? playerState.progress : 1.0
        return Self.elapsedTimeFormatter.string(from: Date(timeIntervalSinceReferenceDate: playerState.duration * percent))
    }
    
    var showWaveformCursor: Bool {
        playerState.playing || dragState.isDragging
    }
    
    var body: some View {
        HStack {
            HStack {
                playPauseButton
                Text(timeLabelContent)
                    .font(.compound.bodySMSemibold)
                    .foregroundColor(.compound.textSecondary)
                    .monospacedDigit()
            }
            GeometryReader { geometry in
                WaveformView(lineWidth: waveformLineWidth, linePadding: waveformLinePadding, waveform: playerState.waveform, progress: playerState.progress, showCursor: showWaveformCursor)
                    // Add a gesture to drag the waveform
                    .gesture(SpatialTapGesture()
                        .simultaneously(with: LongPressGesture())
                        .sequenced(before: DragGesture(minimumDistance: waveformLinePadding, coordinateSpace: .local))
                        .updating($dragState) { value, state, _ in
                            switch value {
                            // (SpatialTap, LongPress) begins.
                            case .first(let spatialLongPress) where spatialLongPress.second == true:
                                // Compute the progress with the spatialTap location
                                let progress = (spatialLongPress.first?.location ?? .zero).x / geometry.size.width
                                state = .pressing(progress: progress)
                            // Long press confirmed, dragging may begin.
                            case .second(let spatialLongPress, let drag) where spatialLongPress.second == true:
                                var progress: Double = tapProgress
                                // Compute the progress with drag location
                                if let loc = drag?.location {
                                    progress = loc.x / geometry.size.width
                                }
                                state = .dragging(progress: progress, distance: geometry.size.width)
                            // Dragging ended or the long press cancelled.
                            default:
                                state = .inactive
                            }
                        })
            }
            .frame(maxWidth: waveformMaxWidth)
        }
        .onChange(of: dragState) { newDragState in
            switch newDragState {
            case .inactive:
                onScrubbing(false)
            case .pressing(let progress):
                tapProgress = progress
                onScrubbing(true)
                feedbackGenerator.prepare()
                sendFeedback = true
            case .dragging(let progress, let totalWidth):
                if sendFeedback {
                    feedbackGenerator.impactOccurred()
                    sendFeedback = false
                }
                let minimumProgress = waveformLinePadding / totalWidth
                let deltaProgress = abs(progress - playerState.progress)
                let deltaTime = playerState.duration * deltaProgress
                if deltaProgress == 0 || deltaProgress >= minimumProgress || deltaTime >= 1.0 {
                    onSeek(max(0, min(progress, 1.0)))
                }
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
                if playerState.loading {
                    ProgressView()
                } else {
                    Image(asset: playerState.playing ? Asset.Images.mediaPause : Asset.Images.mediaPlay)
                        .offset(x: playerState.playing ? 0 : 2)
                        .aspectRatio(contentMode: .fit)
                        .foregroundColor(.compound.iconSecondary)
                }
            }
        }
        .disabled(playerState.loading)
        .frame(width: playPauseButtonSize.width,
               height: playPauseButtonSize.height)
    }
}

private enum DragState: Equatable {
    case inactive
    case pressing(progress: Double)
    case dragging(progress: Double, distance: Double)
    
    var progress: Double {
        switch self {
        case .inactive, .pressing:
            return .zero
        case .dragging(let progress, _):
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
    static let waveform = Waveform(data: [3, 127, 400, 266, 126, 122, 373, 251, 45, 112,
                                          334, 205, 99, 138, 397, 354, 125, 361, 199, 51,
                                          294, 131, 19, 2, 3, 3, 1, 2, 0, 0,
                                          0, 0, 0, 0, 0, 3])
    
    static let playerState: AudioPlayerState = {
        var state = AudioPlayerState(duration: 10.0,
                                     waveform: waveform,
                                     progress: 0.3)
        return state
    }()
    
    static var previews: some View {
        VoiceMessageRoomPlaybackView(playerState: playerState,
                                     onPlayPause: { },
                                     onSeek: { value in Task { await playerState.updateState(progress: value) } },
                                     onScrubbing: { _ in })
        .fixedSize(horizontal: false, vertical: true)
    }
}
