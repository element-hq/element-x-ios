//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension View {
    func progressMask(progress: CGFloat,
                      trackColor: Color = .compound.iconSecondary,
                      backgroundTrackColor: Color = .compound.iconQuaternary) -> some View {
        modifier(ProgressMaskModifier(progress: progress,
                                      trackColor: trackColor,
                                      backgroundTrackColor: backgroundTrackColor))
    }
}

private struct ProgressMaskModifier: ViewModifier {
    private let progress: CGFloat
    private let trackColor: Color
    private let backgroundTrackColor: Color

    init(progress: CGFloat, trackColor: Color, backgroundTrackColor: Color) {
        self.progress = progress
        self.trackColor = trackColor
        self.backgroundTrackColor = backgroundTrackColor
    }

    func body(content: Content) -> some View {
        GeometryReader { geometry in
            ZStack(alignment: .leading) {
                Rectangle()
                    .fill(backgroundTrackColor)
                    .frame(width: geometry.size.width, height: geometry.size.height)
                
                Rectangle()
                    .fill(trackColor)
                    .frame(width: max(0.0, geometry.size.width * progress), height: geometry.size.height)
            }
            .mask {
                content
            }
        }
    }
}
