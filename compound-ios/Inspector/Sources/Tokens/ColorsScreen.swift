//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Compound

struct ColorsScreen: View {
    var body: some View {
        ScreenContent(navigationTitle: "Colors") {
            ForEach(Color.compound.allColors, id: \.name) { color in
                ColorItem(color: color.value, name: color.name)
            }
        }
    }
}

struct ColorItem: View {
    let color: Color
    let name: String
    
    var body: some View {
        HStack {
            swatch
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.compound.bodyLG)
                    .foregroundColor(.compound.textPrimary)
                Text(color.hexValue())
                    .font(.compound.bodySM.monospaced())
                    .foregroundColor(.compound.textSecondary)
            }
        }
    }
    
    var swatch: some View {
        swatchShape
            .foregroundColor(color)
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

private extension Color {
    func hexValue() -> String {
        let uiColor = UIColor(self)
        
        var red: CGFloat = 0
        var green: CGFloat = 0
        var blue: CGFloat = 0
        var alpha: CGFloat = 0
        
        uiColor.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        return "#\(red.asHex)\(green.asHex)\(blue.asHex)"
    }
}

private extension CGFloat {
    var asHex: String {
        String(format:"%02X", Int((self * 255).rounded()))
    }
}

struct ColorsScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ColorsScreen()
        }
        .previewLayout(.fixed(width: 375, height: 700))
    }
}
