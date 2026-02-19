//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct PlaybackSpeedButton: View {
    let speed: VoiceMessagePlaybackSpeed
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Text(speed.placeholder)
                    .font(.compound.bodyXSSemibold)
                    .hidden()

                Text(speed.label)
                    .font(.compound.bodyXSSemibold)
                    .foregroundColor(.compound.iconSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.compound.bgCanvasDefault, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(L10n.a11yPlaybackSpeed)
        .accessibilityValue(speed.label)
    }
}

struct PlaybackSpeedButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        HStack(spacing: 8) {
            ForEach(VoiceMessagePlaybackSpeed.allCases, id: \.self) { speed in
                PlaybackSpeedButton(speed: speed) { }
            }
        }
        .padding()
        .background(Color.gray)
    }
}
