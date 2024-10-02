//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

extension View {
    func scaledPadding(_ length: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        scaledPadding(.all, length, relativeTo: textStyle)
    }
    
    func scaledPadding(_ edges: Edge.Set, _ length: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        modifier(ScaledPaddingModifier(edges: edges, length: length, textStyle: textStyle))
    }
}

private struct ScaledPaddingModifier: ViewModifier {
    let edges: Edge.Set
    @ScaledMetric var length: CGFloat
    
    init(edges: Edge.Set, length: CGFloat, textStyle: Font.TextStyle) {
        self.edges = edges
        _length = ScaledMetric(wrappedValue: length, relativeTo: textStyle)
    }
    
    func body(content: Content) -> some View {
        content.padding(edges, length)
    }
}
