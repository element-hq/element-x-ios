//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

extension View {
    /// Masks this view using the inverted alpha channel of the given view.
    ///
    /// The inverse of `mask(alignment:_:)`.
    func inverseMask(alignment: Alignment = .center, @ViewBuilder _ inverseMask: () -> some View) -> some View {
        mask {
            Rectangle()
                .overlay(alignment: alignment) {
                    inverseMask()
                        .blendMode(.destinationOut) // erases the rectangle wherever `mask` is opaque.
                }
                .compositingGroup()
        }
    }
}
