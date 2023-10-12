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

struct VoiceMessageRecordButton: View {
    @ScaledMetric private var buttonIconSize = 24
    @State private var longPressConfirmed = false
    @State private var buttonPressed = false
    @State private var longPressTask = VoiceMessageButtonTask()

    private let feedbackGenerator = UIImpactFeedbackGenerator(style: .heavy)

    let delayBeforeRecording = 750
    @Binding var showRecordTooltip: Bool
    
    var startRecording: (() -> Void)?
    var stopRecording: (() -> Void)?
    
    var body: some View {
        Button { } label: {
            voiceMessageButtonImage
        }
        .onLongPressGesture(perform: { }, onPressingChanged: { pressing in
            buttonPressed = pressing
            if pressing {
                showRecordTooltip = true
                feedbackGenerator.prepare()
                longPressTask.task = Task {
                    try? await Task.sleep(for: .milliseconds(delayBeforeRecording))
                    guard !Task.isCancelled else {
                        return
                    }
                    feedbackGenerator.impactOccurred()
                    showRecordTooltip = false
                    longPressConfirmed = true
                    startRecording?()
                }
            } else {
                longPressTask.task?.cancel()
                showRecordTooltip = false
                guard longPressConfirmed else { return }
                longPressConfirmed = false
                stopRecording?()
            }
        })
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

private class VoiceMessageButtonTask {
    @CancellableTask var task: Task<Void, Never>?
}

struct VoiceMessageRecordButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VoiceMessageRecordButton(showRecordTooltip: .constant(false))
            .fixedSize(horizontal: true, vertical: true)
    }
}
