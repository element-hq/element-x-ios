//
// Copyright 2025 New Vector Ltd
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct BigIconScreen: View {
    var body: some View {
        ScreenContent(navigationTitle: "Big Icon") {
            BigIcon_Previews.states
        }
    }
}

struct BigIconScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            BigIconScreen()
        }
        .previewLayout(.fixed(width: 375, height: 700))
    }
}
