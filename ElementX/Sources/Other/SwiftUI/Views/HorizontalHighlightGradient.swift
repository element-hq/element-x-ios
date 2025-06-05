//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct HorizontalHighlightGradient: ViewModifier {
    let borderColor: Color
    let primaryColor: Color
    let secondaryColor: Color
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                borderColor
                    .frame(height: 1)
                LinearGradient(colors: [primaryColor, secondaryColor],
                               startPoint: .top,
                               endPoint: .bottom)
            }
            content
                .layoutPriority(1)
        }
    }
}

extension View {
    func highlight(borderColor: Color, primaryColor: Color, secondaryColor: Color) -> some View {
        modifier(HorizontalHighlightGradient(borderColor: borderColor, primaryColor: primaryColor, secondaryColor: secondaryColor))
    }
}
