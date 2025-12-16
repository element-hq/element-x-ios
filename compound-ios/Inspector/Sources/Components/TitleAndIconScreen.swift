//
// Copyright 2025 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct TitleAndIconScreen: View {
    var body: some View {
        ScreenContent(navigationTitle: "Title & Icon") {
            TitleAndIcon_Previews.states
        }
    }
}

struct TitleAndIconScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TitleAndIconScreen()
        }
        .previewLayout(.fixed(width: 375, height: 700))
    }
}
