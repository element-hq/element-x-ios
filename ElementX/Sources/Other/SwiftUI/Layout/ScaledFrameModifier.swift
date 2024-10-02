//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension View {
    func scaledFrame(size: CGFloat, alignment: Alignment = .center, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        scaledFrame(width: size, height: size, alignment: alignment, relativeTo: textStyle)
    }
    
    func scaledFrame(width: CGFloat, height: CGFloat, alignment: Alignment = .center, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        modifier(ScaledFrameModifier(width: width, height: height, alignment: alignment, relativeTo: textStyle))
    }
}

private struct ScaledFrameModifier: ViewModifier {
    @ScaledMetric var width: CGFloat
    @ScaledMetric var height: CGFloat
    let alignment: Alignment
    
    init(width: CGFloat, height: CGFloat, alignment: Alignment, relativeTo textStyle: Font.TextStyle) {
        _width = ScaledMetric(wrappedValue: width, relativeTo: textStyle)
        _height = ScaledMetric(wrappedValue: height, relativeTo: textStyle)
        self.alignment = alignment
    }
    
    func body(content: Content) -> some View {
        content.frame(width: width, height: height, alignment: alignment)
    }
}
