//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

enum VoiceMessageRecordingButtonMode {
    case idle
    case recording
}

struct VoiceMessageRecordingButton: View {
    @Environment(\.isEnabled) private var isEnabled
    
    let mode: VoiceMessageRecordingButtonMode
    var startRecording: (() -> Void)?
    var stopRecording: (() -> Void)?
    
    private let impactFeedbackGenerator = UIImpactFeedbackGenerator()
    
    private var recordIconColour: Color {
        guard isEnabled else { return .compound.iconDisabled }
        return Compound.supportsGlass ? .compound.iconPrimary : .compound.iconSecondary
    }
    
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
                CompoundIcon(Compound.supportsGlass ? \.micOnSolid : \.micOn,
                             size: .medium,
                             relativeTo: .compound.headingLG)
                    .foregroundColor(recordIconColour)
                    .scaledPadding(Compound.supportsGlass ? 10 : 6, relativeTo: .compound.headingLG)
            case .recording:
                CompoundIcon(\.stopSolid,
                             size: Compound.supportsGlass ? .medium : .small,
                             relativeTo: .compound.headingLG)
                    .foregroundColor(.compound.iconOnSolidPrimary)
                    .scaledPadding(Compound.supportsGlass ? 10 : 8, relativeTo: .compound.headingLG)
                    .background(.compound.bgActionPrimaryRest, in: .circle)
                    .compositingGroup()
            }
        }
        .buttonStyle(VoiceMessageRecordingButtonStyle())
        .accessibilityLabel(mode == .idle ? L10n.a11yVoiceMessageRecord : L10n.a11yVoiceMessageStopRecording)
    }
}

private struct VoiceMessageRecordingButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) private var isEnabled
    
    func makeBody(configuration: Configuration) -> some View {
        if #available(iOS 26, *) {
            if isEnabled {
                configuration.label
                    .snapshotableGlassEffect(.regular.interactive(),
                                             snapshotBackground: .compound.bgSubtleSecondary,
                                             in: .circle)
            } else {
                configuration.label
                    .background(.compound.bgSubtlePrimary, in: .circle)
            }
        } else {
            configuration.label
                .opacity(configuration.isPressed ? 0.6 : 1)
        }
    }
}

struct VoiceMessageRecordingButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        HStack(spacing: 12) {
            VoiceMessageRecordingButton(mode: .idle)
                .disabled(true)
            VoiceMessageRecordingButton(mode: .idle)
            VoiceMessageRecordingButton(mode: .recording)
        }
    }
}
