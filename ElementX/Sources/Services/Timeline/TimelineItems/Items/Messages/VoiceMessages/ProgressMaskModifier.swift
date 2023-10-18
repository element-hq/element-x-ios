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
