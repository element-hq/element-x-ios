//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Compound

struct ShareSheetScreen: View {
    var body: some View {
        ScreenContent(navigationTitle: "Share Sheets") {
            Text("This component will be rendered differently when running on macOS.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            ShareLink(item: URL(string: "https://element.io")!, subject: Text("The subject"), message: Text("The message"))
                .padding(.top)
        }
    }
}

struct ShareSheetScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ShareSheetScreen()
        }
        .previewLayout(.fixed(width: 375, height: 750))
    }
}
