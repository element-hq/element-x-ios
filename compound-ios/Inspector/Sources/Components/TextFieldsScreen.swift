//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import DesignKit
import SwiftUI

struct TextFieldsScreen: View {
    var body: some View {
        ScreenContent(navigationTitle: "Text Fields") {
            BorderedInputFieldStyle_Previews.states
        }
    }
}

struct TextFieldsScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            TextFieldsScreen()
        }
        .previewLayout(.fixed(width: 375, height: 700))
    }
}
