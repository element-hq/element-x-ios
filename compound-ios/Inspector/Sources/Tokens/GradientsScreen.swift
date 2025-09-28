//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Compound

struct GradientsScreen: View {
    var body: some View {
        ScreenContent(navigationTitle: "Colors") {
            ForEach(Gradient.compound.allValues, id: \.name) { gradient in
                GradientItem(gradient: gradient.value, name: gradient.name)
            }
        }
    }
}

struct GradientItem: View {
    let gradient: Gradient
    let name: String
    
    var body: some View {
        HStack {
            swatch
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.compound.bodyLG)
                    .foregroundColor(.compound.textPrimary)
            }
        }
    }
    
    var swatch: some View {
        swatchShape
            .foregroundStyle(gradient)
            .frame(height: 40)
            .aspectRatio(1, contentMode: .fit)
            .overlay {
                swatchShape
                    .strokeBorder(Color.compound.iconPrimary, lineWidth: 1.5)
                    .opacity(0.2)
            }
    }
    
    var swatchShape: some InsettableShape {
        RoundedRectangle(cornerRadius: 12, style: .continuous)
    }
}

struct GradientsScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ColorsScreen()
        }
        .previewLayout(.fixed(width: 375, height: 700))
    }
}
