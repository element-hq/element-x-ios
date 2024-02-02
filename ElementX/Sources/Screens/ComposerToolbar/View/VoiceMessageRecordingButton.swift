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
                CompoundIcon(\.micOn, size: .medium, relativeTo: .title)
                    .foregroundColor(.compound.iconSecondary)
                    .scaledPadding(10, relativeTo: .title)
            case .recording:
                CompoundIcon(asset: Asset.Images.stopRecording, size: .medium, relativeTo: .title)
                    .foregroundColor(.compound.iconOnSolidPrimary)
                    .scaledPadding(6, relativeTo: .title)
                    .background(
                        Circle()
                            .foregroundColor(.compound.bgActionPrimaryRest)
                    )
                    .scaledPadding(4, relativeTo: .title)
            }
        }
        .buttonStyle(VoiceMessageRecordingButtonStyle())
        .accessibilityLabel(mode == .idle ? L10n.a11yVoiceMessageRecord : L10n.a11yVoiceMessageStopRecording)
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
        HStack(spacing: 8) {
            VoiceMessageRecordingButton(mode: .idle)
            
            VoiceMessageRecordingButton(mode: .recording)
        }
    }
}
