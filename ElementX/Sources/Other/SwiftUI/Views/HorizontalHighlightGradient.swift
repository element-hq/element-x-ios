//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

extension View {
    func highlight(gradient: Gradient, borderColor: Color) -> some View {
        modifier(HorizontalHighlightGradient(gradient: gradient, borderColor: borderColor))
    }
}

struct HorizontalHighlightGradient: ViewModifier {
    let gradient: Gradient
    let borderColor: Color
    
    func body(content: Content) -> some View {
        ZStack(alignment: .top) {
            VStack(spacing: 0) {
                borderColor
                    .frame(height: 1)
                LinearGradient(gradient: gradient,
                               startPoint: .top,
                               endPoint: .bottom)
            }
            content
                .layoutPriority(1)
        }
    }
}
