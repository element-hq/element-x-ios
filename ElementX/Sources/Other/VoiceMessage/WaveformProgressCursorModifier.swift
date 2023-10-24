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

import Compound
import SwiftUI

extension View {
    func waveformProgressCursor(progress: CGFloat,
                                color: Color = .compound.iconAccentTertiary,
                                width: CGFloat = 2,
                                opacity: CGFloat = 1.0) -> some View {
        modifier(WaveformProgressCursorModifier(progress: progress,
                                                color: color,
                                                width: width,
                                                opacity: opacity))
    }
}

private struct WaveformProgressCursorModifier: ViewModifier {
    private let progress: CGFloat
    private let color: Color
    private let width: CGFloat
    private let opacity: CGFloat
    
    init(progress: CGFloat, color: Color, width: CGFloat, opacity: CGFloat) {
        self.progress = progress
        self.color = color
        self.width = width
        self.opacity = opacity
    }
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .overlay(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 1)
                        .fill(color)
                        .offset(CGSize(width: progress * geometry.size.width, height: 0.0))
                        .frame(width: width, height: geometry.size.height)
                        .opacity(opacity)
                }
        }
    }
}
