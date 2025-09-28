//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

public extension View {
    /// Adds an equal padding amount to all edges of this view, scaled relative to the user's selected font size.
    func scaledPadding(_ length: CGFloat, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        scaledPadding(.all, length, relativeTo: textStyle)
    }
    
    /// Adds an equal padding amount to specific edges of this view, scaled relative to the user's selected font size.
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

// MARK: - Previews

struct ScaledPaddingModifier_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack {
            ForEach(DynamicTypeSize.allCases, id: \.self) { size in
                userProfileButtonLabel
                    .dynamicTypeSize(size)
            }
        }
    }
    
    static var userProfileButtonLabel: some View {
        CompoundIcon(\.userProfile, size: .medium, relativeTo: .title)
            .foregroundStyle(.compound.iconOnSolidPrimary)
            .scaledPadding(6, relativeTo: .title)
            .background(.compound.bgAccentRest, in: Circle())
    }
}
