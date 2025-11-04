//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension View {
    /// Animates the view in/out from its top edge when `isVisible`
    /// is toggled, revealing the view in the style of a banner.
    func banner(isVisible: Bool) -> some View {
        ZStack {
            if isVisible {
                transition(.move(edge: .top))
            } else {
                hidden()
            }
        }
        .animation(.elementDefault, value: isVisible)
        .clipped()
    }
}
