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
    @ObservedObject var playbackViewState: VoiceRoomPlaybackViewState

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)
    @State private var sendFeedback = false
    
    private let waveformMaxWidth: CGFloat = 150
    private let playPauseButtonSize = CGSize(width: 32, height: 32)
    
    private static let elapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "m:ss"
        return dateFormatter
    }()
    
    var onPlayPause: () -> Void = { }
    var onSeek: (Double) -> Void = { _ in }
    var onScrubbing: (Bool) -> Void = { _ in }
    
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
    
    @GestureState private var dragState = DragState.inactive
    @State private var tapProgress: Double = .zero
    
    var timeLabelContent: String {
        // Display the duration if progress is 0.0
        let percent = playbackViewState.progress > 0.0 ? playbackViewState.progress : 1.0
        return Self.elapsedTimeFormatter.string(from: Date(timeIntervalSinceReferenceDate: playbackViewState.duration * percent))
    }
    
    var showWaveformCursor: Bool {
        playbackViewState.playing || dragState.isDragging
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
            .padding(.vertical, 6)
            GeometryReader { geometry in
                WaveformView(waveform: playbackViewState.waveform, progress: playbackViewState.progress, showCursor: showWaveformCursor)
                    // Add a gesture to drag the waveform
                    .gesture(SpatialTapGesture()
                        .simultaneously(with: LongPressGesture())
                        .sequenced(before: DragGesture(coordinateSpace: .local))
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
                                state = .dragging(progress: progress)
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
            case .dragging(let progress):
                if sendFeedback {
                    feedbackGenerator.impactOccurred()
                    sendFeedback = false
                }
                if abs(progress - playbackViewState.progress) > 0.01 {
                    onSeek(max(0, min(progress, 1.0)))
                }
            }
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
    }
    
    @ViewBuilder
    var playPauseButton: some View {
        Button {
            onPlayPause()
        } label: {
            Image(systemName: playbackViewState.playing ? "pause.fill" : "play.fill")
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

struct VoiceRoomPlaybackView_Previews: PreviewProvider, TestablePreview {
    static let waveform = Waveform(data: [3, 127, 400, 266, 126, 122, 373, 251, 45, 112,
                                          334, 205, 99, 138, 397, 354, 125, 361, 199, 51,
                                          294, 131, 19, 2, 3, 3, 1, 2, 0, 0,
                                          0, 0, 0, 0, 0, 3])
    
    static let playbackViewState = VoiceRoomPlaybackViewState(duration: 10.0,
                                                              waveform: waveform,
                                                              progress: 0.3)
    
    static var previews: some View {
        VoiceRoomPlaybackView(playbackViewState: playbackViewState,
                              onPlayPause: { },
                              onSeek: { value in Task { await playbackViewState.updateState(progress: value) } })
            .fixedSize(horizontal: false, vertical: true)
    }
}
