//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct RowDivider: ViewModifier {
    @Environment(\.pixelLength) var pixelLength: CGFloat
    let alignment: Alignment
    let horizontalInsets: CGFloat
    
    func body(content: Content) -> some View {
        content
            .overlay(alignment: alignment) {
                Rectangle()
                    .fill(Color.compound.borderDisabled)
                    .frame(height: pixelLength)
                    .padding(.trailing, -horizontalInsets)
            }
    }
}

extension View {
    func rowDivider(alignment: Alignment = .bottom, horizontalInsets: CGFloat) -> some View {
        modifier(RowDivider(alignment: alignment, horizontalInsets: horizontalInsets))
    }
}
