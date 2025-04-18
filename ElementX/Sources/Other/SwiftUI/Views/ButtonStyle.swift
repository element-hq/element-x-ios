//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct ElementCallButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .padding(.horizontal, 16.0)
            .padding(.vertical, 4.0)
            .foregroundColor(.compound.bgCanvasDefault)
            .background(Color.compound.iconAccentTertiary)
            .clipShape(Capsule())
    }
}
