//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct PlaybackSpeedButton: View {
    let speed: Float
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            ZStack {
                Text("0.0x")
                    .font(.compound.bodyXSSemibold)
                    .hidden()

                Text(speedLabel)
                    .font(.compound.bodyXSSemibold)
                    .foregroundColor(.compound.iconSecondary)
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 2)
            .background(.compound.bgCanvasDefault, in: RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(UntranslatedL10n.a11yPlaybackSpeed(speedLabel))
    }

    private var speedLabel: String {
        if speed == Float(Int(speed)) {
            "\(Int(speed))x"
        } else {
            String(format: "%gx", speed)
        }
    }
}

struct PlaybackSpeedButton_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        HStack(spacing: 8) {
            PlaybackSpeedButton(speed: 0.5) { }
            PlaybackSpeedButton(speed: 1.0) { }
            PlaybackSpeedButton(speed: 1.5) { }
            PlaybackSpeedButton(speed: 2.0) { }
        }
        .padding()
        .background(Color.gray)
    }
}
