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
    var startRecording: (() -> Void)?
    var stopRecording: ((_ minimumRecordTimeReached: Bool) -> Void)?
    
    @ScaledMetric private var tooltipPointerHeight = 6
    
    @State private var buttonPressed = false
    @State private var recordingStartTime: Date?
    @State private var showTooltip = false
    @State private var frame: CGRect = .zero
    
    private let minimumRecordingDuration = 1.0
    private let tooltipDuration = 1.0
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator()
    private let notificationFeedbackGenerator = UINotificationFeedbackGenerator()
    
    var body: some View {
        Button { } label: {
            CompoundIcon(buttonPressed ? \.micOnSolid : \.micOnOutline)
                .foregroundColor(.compound.iconSecondary)
                .padding(EdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6))
        }
        .readFrame($frame, in: .global)
        .accessibilityLabel(L10n.a11yVoiceMessageRecord)
        .onLongPressGesture { } onPressingChanged: { isPressing in
            buttonPressed = isPressing
            
            if isPressing {
                showTooltip = false
                recordingStartTime = Date.now
                impactFeedbackGenerator.impactOccurred()
                startRecording?()
            } else {
                if let recordingStartTime, Date.now.timeIntervalSince(recordingStartTime) < minimumRecordingDuration {
                    withElementAnimation {
                        showTooltip = true
                    }
                    notificationFeedbackGenerator.notificationOccurred(.error)
                    stopRecording?(false)
                } else {
                    impactFeedbackGenerator.impactOccurred()
                    stopRecording?(true)
                }
            }
        }
        .overlay(alignment: .bottomTrailing) {
            if showTooltip {
                tooltipView
                    .offset(y: -frame.height - tooltipPointerHeight)
            }
        }
    }
    
    private var tooltipView: some View {
        VoiceMessageRecordingButtonTooltipView(text: L10n.screenRoomVoiceMessageTooltip,
                                               pointerHeight: tooltipPointerHeight,
                                               pointerLocation: frame.midX,
                                               pointerLocationCoordinateSpace: .global)
            .allowsHitTesting(false)
            .fixedSize()
            .onAppear {
                DispatchQueue.main.asyncAfter(deadline: .now() + tooltipDuration) {
                    withElementAnimation {
                        showTooltip = false
                    }
                }
            }
    }
}

struct VoiceMessageRecordingButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VoiceMessageRecordingButton()
            .fixedSize(horizontal: true, vertical: true)
    }
}
