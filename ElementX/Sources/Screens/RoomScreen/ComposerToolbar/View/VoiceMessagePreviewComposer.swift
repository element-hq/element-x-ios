//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
    @GestureState var isDragging = false

    let onPlay: () -> Void
    let onPause: () -> Void
    let onSeek: (Double) -> Void
    let onScrubbing: (Bool) -> Void

    var timeLabelContent: String {
        // Display the duration if progress is 0.0
        let percent = playerState.progress > 0.0 ? playerState.progress : 1.0
        // If the duration is greater or equal 10 minutes, use the long format
        let elapsed = Date(timeIntervalSinceReferenceDate: playerState.duration * percent)
        return DateFormatter.elapsedTimeFormatter.string(from: elapsed)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            VoiceMessageButton(state: .init(playerState.playerButtonPlaybackState),
                               size: .small,
                               action: onPlayPause)
            Text(timeLabelContent)
                .lineLimit(1)
                .font(.compound.bodySMSemibold)
                .foregroundColor(.compound.textSecondary)
                .monospacedDigit()
                .fixedSize(horizontal: true, vertical: true)

            waveformView
                .waveformInteraction(isDragging: $isDragging,
                                     progress: playerState.progress,
                                     showCursor: playerState.showProgressIndicator,
                                     onSeek: onSeek)
        }
        .onChange(of: isDragging) { isDragging in
            onScrubbing(isDragging)
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
}

private extension DateFormatter {
    static let elapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm:ss"
        return dateFormatter
    }()
}

struct VoiceMessagePreviewComposer_Previews: PreviewProvider, TestablePreview {
    static let playerState = AudioPlayerState(id: .recorderPreview,
                                              title: L10n.commonVoiceMessage,
                                              duration: 10.0,
                                              waveform: EstimatedWaveform.mockWaveform,
                                              progress: 0.4)
    
    static let waveformData: [Float] = Array(repeating: 1.0, count: 1000)
    
    static var previews: some View {
        VoiceMessagePreviewComposer(playerState: playerState, waveform: .data(waveformData), onPlay: { }, onPause: { }, onSeek: { _ in }, onScrubbing: { _ in })
            .fixedSize(horizontal: false, vertical: true)
    }
}
