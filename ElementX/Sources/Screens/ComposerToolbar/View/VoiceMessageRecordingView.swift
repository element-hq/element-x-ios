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
            
    var timeLabelContent: String {
        Self.elapsedTimeFormatter.string(from: Date(timeIntervalSinceReferenceDate: recorderState.duration))
    }
    
    var body: some View {
        HStack {
            Circle()
                .frame(width: recordingIndicatorSize, height: recordingIndicatorSize)
                .foregroundColor(.red)
            Text(timeLabelContent)
                .lineLimit(1)
                .font(.compound.bodySMSemibold)
                .foregroundColor(.compound.textSecondary)
                .monospacedDigit()
                .fixedSize()
            WaveformView(lineWidth: waveformLineWidth, linePadding: waveformLinePadding, waveform: recorderState.waveform, progress: 0, showCursor: false)
        }
        .padding(.leading, 2)
        .padding(.trailing, 8)
    }
}

struct VoiceMessageRecordingView_Previews: PreviewProvider, TestablePreview {
    static let waveform = Waveform(data: [3, 127, 400, 266, 126, 122, 373, 251, 45, 112,
                                          334, 205, 99, 138, 397, 354, 125, 361, 199, 51,
                                          294, 131, 19, 2, 3, 3, 1, 2, 0, 0,
                                          0, 0, 0, 0, 0, 3])
    
    static let recorderState = AudioRecorderState()
    
    static var previews: some View {
        VoiceMessageRecordingView(recorderState: recorderState)
            .fixedSize(horizontal: false, vertical: true)
    }
}
