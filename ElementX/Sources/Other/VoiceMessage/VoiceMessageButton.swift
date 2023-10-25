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
    @ScaledMetric private var imageWidth: CGFloat = 12
    @ScaledMetric private var imageHeight: CGFloat = 14

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
        .disabled(state == .loading)
        .background(Circle().foregroundColor(.compound.bgCanvasDefault))
    }

    @ViewBuilder
    private var buttonLabel: some View {
        switch state {
        case .loading:
            ProgressView()
        case .playing, .paused:
            let imageAsset = state == .playing ? Asset.Images.mediaPause : Asset.Images.mediaPlay
            let accessibilityLabel = state == .playing ? L10n.a11yPause : L10n.a11yPlay
            let offset: CGFloat = state == .playing ? 0 : 2

            Image(asset: imageAsset)
                .resizable()
                .scaledToFit()
                .frame(width: imageWidth, height: imageHeight)
                .offset(x: offset)
                .aspectRatio(contentMode: .fit)
                .foregroundColor(.compound.iconSecondary)
                .accessibilityLabel(accessibilityLabel)
        }
    }
}

struct VoiceMessageButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack {
            HStack {
                VoiceMessageButton(state: .paused, size: .small, action: { })
                VoiceMessageButton(state: .paused, size: .medium, action: { })
            }
            HStack {
                VoiceMessageButton(state: .playing, size: .small, action: { })
                VoiceMessageButton(state: .playing, size: .medium, action: { })
            }
            HStack {
                VoiceMessageButton(state: .loading, size: .small, action: { })
                VoiceMessageButton(state: .loading, size: .medium, action: { })
            }
        }
        .padding()
        .background(Color.gray)
    }
}
