//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct WaveformCursorView: View {
    var color: Color = .compound.iconAccentTertiary

    var body: some View {
        RoundedRectangle(cornerRadius: 1)
            .fill(color)
    }
}

struct WaveformCursorView_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        WaveformCursorView(color: .compound.iconAccentTertiary)
            .frame(width: 2, height: 25)
    }
}
