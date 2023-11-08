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
    case standard
    case recording
}

struct VoiceMessageRecordingButton: View {
    var mode: VoiceMessageRecordingButtonMode
    var startRecording: (() -> Void)?
    var stopRecording: (() -> Void)?
    
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator()
    
    var body: some View {
        Button {
            impactFeedbackGenerator.impactOccurred()
            switch mode {
            case .standard:
                startRecording?()
            case .recording:
                stopRecording?()
            }
        } label: { }
            .accessibilityLabel(L10n.a11yVoiceMessageRecord)
            .buttonStyle(VoiceMessageRecordingButtonStyle(mode: mode))
    }
}

private struct VoiceMessageRecordingButtonStyle: ButtonStyle {
    let mode: VoiceMessageRecordingButtonMode
    
    func makeBody(configuration: Configuration) -> some View {
        Group {
            switch mode {
            case .standard:
                CompoundIcon(configuration.isPressed ? \.micOnSolid : \.micOnOutline)
                    .foregroundColor(.compound.iconSecondary)
                    .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
            case .recording:
                Image(systemName: "stop.circle.fill")
                    .resizable()
                    .frame(width: 34, height: 34)
            }
        }
    }
}

struct VoiceMessageRecordingButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        HStack {
            VoiceMessageRecordingButton(mode: .standard)
                .fixedSize(horizontal: true, vertical: true)
            
            VoiceMessageRecordingButton(mode: .recording)
                .fixedSize(horizontal: true, vertical: true)
        }
    }
}
