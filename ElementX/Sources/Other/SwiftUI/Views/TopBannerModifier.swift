//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension View {
    /// Overlays the given banner view at the top edge of this view, using a
    /// slide from the top edge when `isVisible` is toggled.
    func topBanner(_ banner: some View, isVisible: Bool) -> some View {
        overlay(alignment: .top) {
            ZStack {
                if isVisible {
                    banner.transition(.move(edge: .top))
                } else {
                    // An equal amount of space needs to be reserved in order for the transition to work.
                    banner.hidden()
                }
            }
            .animation(.elementDefault, value: isVisible)
            .clipped()
        }
    }
}
