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
