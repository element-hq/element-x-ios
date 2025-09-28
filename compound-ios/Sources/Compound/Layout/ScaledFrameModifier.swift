//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

public extension View {
    /// Positions this view within an invisible frame with a square size that scales relative to the user's selected font size.
    func scaledFrame(size: CGFloat, alignment: Alignment = .center, relativeTo textStyle: Font.TextStyle = .body) -> some View {
        scaledFrame(width: size, height: size, alignment: alignment, relativeTo: textStyle)
    }
    
    /// Positions this view within an invisible frame with a size that scales relative to the user's selected font size.
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

// MARK: - Previews

struct ScaledFrameModifier_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        VStack {
            ForEach(DynamicTypeSize.allCases, id: \.self) { size in
                likeButtonLabel
                    .dynamicTypeSize(size)
            }
        }
    }
    
    static var likeButtonLabel: some View {
        Image(systemSymbol: .heartCircleFill)
            .resizable()
            .foregroundStyle(.compound.iconAccentTertiary)
            .scaledFrame(size: 24, relativeTo: .title)
    }
}
