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

    init(state: State, size: Size, action: @escaping () -> Void) {
        switch size {
        case .small:
            _buttonSize = .init(wrappedValue: 30)
        case .medium:
            _buttonSize = .init(wrappedValue: 36)
        }
        
        self.state = state
        self.action = action
    }

    var body: some View {
        Button(action: action) {
            buttonLabel
                .frame(width: buttonSize, height: buttonSize)
        }
        .animation(nil, value: state)
        .buttonStyle(VoiceMessageButtonStyle())
        .disabled(state == .loading)
        .background(Circle().foregroundColor(.compound.bgCanvasDefault))
        .accessibilityLabel(accessibilityLabel)
    }

    @ViewBuilder
    private var buttonLabel: some View {
        switch state {
        case .loading:
            ProgressView()
        case .playing, .paused:
            let imageAsset = state == .playing ? Asset.Images.mediaPause : Asset.Images.mediaPlay
            let offset: CGFloat = state == .playing ? 0 : 2

            Image(asset: imageAsset)
                .resizable()
                .scaledToFit()
                .scaledFrame(width: 12, height: 14)
                .offset(x: offset)
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

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .foregroundColor(isEnabled ? .compound.textSecondary.opacity(configuration.isPressed ? 0.6 : 1) : .compound.iconDisabled)
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
                VoiceMessageButton(state: .paused, size: .small, action: { })
                VoiceMessageButton(state: .paused, size: .medium, action: { })
            }
            HStack(spacing: 8) {
                VoiceMessageButton(state: .playing, size: .small, action: { })
                VoiceMessageButton(state: .playing, size: .medium, action: { })
            }
        }
        .padding()
        .background(Color.gray)
    }
}
