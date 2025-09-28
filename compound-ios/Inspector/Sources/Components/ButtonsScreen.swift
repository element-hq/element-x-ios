//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ButtonsScreen: View {
    var body: some View {
        ScreenContent(navigationTitle: "Buttons") {
            CompoundButtonStyle_Previews.states
            SendButton_Previews.states
        }
    }
}

struct ButtonsScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ButtonsScreen()
        }
        .previewLayout(.fixed(width: 375, height: 700))
    }
}
