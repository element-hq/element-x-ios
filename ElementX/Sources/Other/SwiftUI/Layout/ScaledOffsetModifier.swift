//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension View {
    func scaledOffset(x: CGFloat = 0, y: CGFloat = 0, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        modifier(ScaledOffsetModifier(x: x, y: y, relativeTo: textStyle))
    }
}

private struct ScaledOffsetModifier: ViewModifier {
    @ScaledMetric var x: CGFloat
    @ScaledMetric var y: CGFloat
    
    init(x: CGFloat, y: CGFloat, relativeTo textStyle: Font.TextStyle) {
        _x = ScaledMetric(wrappedValue: x, relativeTo: textStyle)
        _y = ScaledMetric(wrappedValue: y, relativeTo: textStyle)
    }
    
    func body(content: Content) -> some View {
        content.offset(x: x, y: y)
    }
}
