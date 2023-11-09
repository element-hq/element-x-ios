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
import SwiftUI

enum VoiceMessageRecordingButtonMode {
    case idle
    case recording
}

struct VoiceMessageRecordingButton: View {
    let mode: VoiceMessageRecordingButtonMode
    var startRecording: (() -> Void)?
    var stopRecording: (() -> Void)?
    
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator()
    @ScaledMetric private var recordingImageSize = 16
    
    var body: some View {
        Button {
            impactFeedbackGenerator.impactOccurred()
            switch mode {
            case .idle:
                startRecording?()
            case .recording:
                stopRecording?()
            }
        } label: {
            switch mode {
            case .idle:
                CompoundIcon(\.micOnOutline, size: .medium, relativeTo: .title)
                    .foregroundColor(.compound.iconSecondary)
                    .frame(width: recordingImageSize, height: recordingImageSize)
                    .padding(14)
            case .recording:
                Image(systemName: "stop.fill")
                    .resizable()
                    .frame(width: recordingImageSize, height: recordingImageSize)
                    .foregroundColor(.compound.iconOnSolidPrimary)
                    .font(.compound.bodyLG)
                    .padding(10)
                    .background {
                        Circle()
                            .foregroundColor(.compound.iconPrimary)
                    }
                    .padding(4)

            }
        }
        .buttonStyle(VoiceMessageRecordingButtonStyle())
        .accessibilityLabel(L10n.a11yVoiceMessageRecord)
    }
}

private struct VoiceMessageRecordingButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.6 : 1)
    }
}

struct VoiceMessageRecordingButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        HStack {
            VoiceMessageRecordingButton(mode: .idle)
            
            VoiceMessageRecordingButton(mode: .recording)
        }
    }
}
