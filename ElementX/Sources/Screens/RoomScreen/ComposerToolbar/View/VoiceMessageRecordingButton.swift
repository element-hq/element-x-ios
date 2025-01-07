//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
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
                CompoundIcon(\.micOn, size: .medium, relativeTo: .compound.headingLG)
                    .foregroundColor(.compound.iconSecondary)
                    .scaledPadding(10, relativeTo: .compound.headingLG)
            case .recording:
                CompoundIcon(asset: Asset.Images.stopRecording, size: .medium, relativeTo: .compound.headingLG)
                    .foregroundColor(.compound.iconOnSolidPrimary)
                    .scaledPadding(6, relativeTo: .compound.headingLG)
                    .background(.compound.bgActionPrimaryRest, in: Circle())
                    .scaledPadding(4, relativeTo: .compound.headingLG)
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
