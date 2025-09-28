//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Compound
import HyperionCore

struct ListScreen: View {
    var body: some View {
        ListRow_Previews.previews
            .navigationTitle("Lists")
    }
}

struct ListScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ListScreen()
        }
        .previewLayout(.fixed(width: 375, height: 700))
    }
}
