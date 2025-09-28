//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Compound

struct FontsScreen: View {
    var body: some View {
        ScreenContent(navigationTitle: "Fonts") {
            ForEach(Font.compound.allValues, id: \.name) { font in
                FontItem(font: font.value, name: font.name)
            }
        }
    }
}

struct FontItem: View {
    let font: Font
    let name: String
    
    var body: some View {
        Text(name)
            .font(font)
            .foregroundColor(.compound.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}

struct FontsScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            FontsScreen()
        }
        .previewLayout(.fixed(width: 375, height: 750))
    }
}
