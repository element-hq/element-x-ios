//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import DSWaveformImage
import DSWaveformImageViews
import Foundation
import SwiftUI

struct VoiceMessageRecordingView: View {
    @ObservedObject var recorderState: AudioRecorderState
    @ScaledMetric private var waveformLineWidth = 2.0
    @ScaledMetric private var waveformLinePadding = 2.0
    @ScaledMetric private var recordingIndicatorSize = 8

    private static let elapsedTimeFormatter: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "mm:ss"
        return dateFormatter
    }()
            
    private var timeLabelContent: String {
        Self.elapsedTimeFormatter.string(from: Date(timeIntervalSinceReferenceDate: recorderState.duration))
    }
    
    private var configuration: Waveform.Configuration {
        .init(style: .striped(.init(color: .compound.iconSecondary, width: waveformLineWidth, spacing: waveformLinePadding)),
              verticalScalingFactor: 1.0)
    }
    
    var body: some View {
        HStack(spacing: 8) {
            VoiceMessageRecordingBadge()
                .frame(width: recordingIndicatorSize, height: recordingIndicatorSize)

            Text(timeLabelContent)
                .lineLimit(1)
                .font(.compound.bodySMSemibold)
                .foregroundColor(.compound.textSecondary)
                .monospacedDigit()
                .fixedSize()
            
            WaveformLiveCanvas(samples: recorderState.waveformSamples,
                               configuration: configuration)
        }
        .padding(.leading, 2)
        .padding(.trailing, 8)
    }
}

private struct VoiceMessageRecordingBadge: View {
    @State private var opacity: CGFloat = 0

    var body: some View {
        Circle()
            .foregroundColor(.red)
            .opacity(opacity)
            .onAppear {
                withElementAnimation(.easeOut(duration: 1).repeatForever(autoreverses: true)) {
                    opacity = 1
                }
            }
    }
}

struct VoiceMessageRecordingView_Previews: PreviewProvider, TestablePreview {
    static let recorderState = AudioRecorderState()
    
    static var previews: some View {
        VoiceMessageRecordingView(recorderState: recorderState)
            .fixedSize(horizontal: false, vertical: true)
    }
}
