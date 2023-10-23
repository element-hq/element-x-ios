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

struct VoiceMessageRecordingButton: View {
    @ScaledMetric private var buttonIconSize = 24
    @State private var buttonPressed = false

    var startRecording: (() -> Void)?
    var stopRecording: (() -> Void)?
    
    var body: some View {
        Button { } label: {
            voiceMessageButtonImage
        }
        .onLongPressGesture { } onPressingChanged: { isPressing in
            buttonPressed = isPressing
            if isPressing {
                // Start recording
                startRecording?()
            } else {
                // Stop recording
                stopRecording?()
            }
        }
        .fixedSize()
    }
    
    @ViewBuilder
    private var voiceMessageButtonImage: some View {
        (buttonPressed ? Image(asset: Asset.Images.micFill) : Image(asset: Asset.Images.mic))
            .resizable()
            .frame(width: buttonIconSize, height: buttonIconSize)
            .foregroundColor(.compound.iconSecondary)
            .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
            .accessibilityLabel(L10n.a11yVoiceMessageRecord)
    }
}

struct VoiceMessageRecordingButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VoiceMessageRecordingButton()
            .fixedSize(horizontal: true, vertical: true)
    }
}
