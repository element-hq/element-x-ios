//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct VoiceMessageButton: View {
    @ScaledMetric private var buttonSize: CGFloat
    
    enum State {
        case loading
        case playing
        case paused
    }
    
    enum Size {
        case small
        case medium
    }
    
    let state: State
    let action: () -> Void
    
    let iconSize: CompoundIcon.Size
    let iconColor: Color
    
    init(state: State, size: Size, action: @escaping () -> Void) {
        switch size {
        case .small:
            _buttonSize = .init(wrappedValue: 30)
            iconSize = .small
            iconColor = .compound.iconPrimary
        case .medium:
            _buttonSize = .init(wrappedValue: 36)
            iconSize = .medium
            iconColor = .compound.iconSecondary
        }
        
        self.state = state
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            buttonLabel
                .frame(width: buttonSize, height: buttonSize)
                .overlay {
                    Circle().stroke(.compound.borderInteractiveSecondary)
                }
        }
        .animation(nil, value: state)
        .buttonStyle(VoiceMessageButtonStyle(color: iconColor))
        .disabled(state == .loading)
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var buttonLabel: some View {
        switch state {
        case .loading:
            ProgressView()
        case .playing, .paused:
            CompoundIcon(state == .playing ? \.pauseSolid : \.playSolid,
                         size: iconSize,
                         relativeTo: .compound.headingLG)
        }
    }
    
    private var accessibilityLabel: String {
        switch state {
        case .loading:
            return ""
        case .playing:
            return L10n.a11yPause
        case .paused:
            return L10n.a11yPlay
        }
    }
}

private struct VoiceMessageButtonStyle: ButtonStyle {
    @Environment(\.isEnabled) var isEnabled: Bool
    
    let color: Color

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? color.opacity(configuration.isPressed ? 0.6 : 1) : .compound.iconDisabled)
            .background(Circle()
                .foregroundColor(configuration.isPressed ? .compound.bgSubtlePrimary : .compound.bgCanvasDefault))
    }
}

extension VoiceMessageButton.State {
    init(_ state: AudioPlayerPlaybackState) {
        switch state {
        case .loading:
            self = .loading
        case .playing:
            self = .playing
        case .stopped, .error, .readyToPlay:
            self = .paused
        }
    }
}

struct VoiceMessageButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack(spacing: 8) {
            HStack(spacing: 8) {
                VoiceMessageButton(state: .paused, size: .small) { }
                VoiceMessageButton(state: .paused, size: .medium) { }
            }
            HStack(spacing: 8) {
                VoiceMessageButton(state: .playing, size: .small) { }
                VoiceMessageButton(state: .playing, size: .medium) { }
            }
        }
        .padding()
        .background(.compound.bgSubtleSecondary)
    }
}
