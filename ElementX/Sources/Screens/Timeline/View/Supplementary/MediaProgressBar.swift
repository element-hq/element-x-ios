//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

/// A 2pt strip flush with the bottom edge of a piece of media, filling from the leading edge in
/// the accent green as a transfer progresses: uploads in the timeline, downloads in the viewer.
/// Nothing when there's no progress to show.
struct MediaProgressBar: View {
    /// 0...1, `nil` hides the bar.
    let progress: Double?
    
    var body: some View {
        if let progress {
            GeometryReader { geometry in
                Rectangle()
                    .fill(.compound.iconAccentPrimary)
                    .frame(width: geometry.size.width * min(max(progress, 0), 1))
                    .animation(.linear(duration: 0.15), value: progress)
            }
            .frame(height: 2)
            .accessibilityElement()
            .accessibilityLabel(L10n.commonSending)
            .accessibilityValue(Text(progress, format: .percent.precision(.fractionLength(0))))
        }
    }
}

struct MediaProgressBar_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        Rectangle()
            .fill(.gray)
            .frame(width: 240, height: 160)
            .overlay(alignment: .bottom) { MediaProgressBar(progress: 0.4) }
    }
}
