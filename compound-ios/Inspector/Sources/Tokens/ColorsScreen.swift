//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

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
    @Environment(\.self) private var environment
    
    let color: Color
    let name: String
    
    var body: some View {
        HStack {
            swatch
            
            VStack(alignment: .leading) {
                Text(name)
                    .font(.compound.bodyLG)
                    .foregroundColor(.compound.textPrimary)
                Text(color.hexValue(in: environment))
                    .font(.compound.bodySM.monospaced())
                    .foregroundColor(.compound.textSecondary)
            }
            .layoutPriority(1)
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
    func hexValue(in environment: EnvironmentValues) -> String {
        let resolved = resolve(in: environment)
        return if resolved.opacity == 1 {
            "#\(resolved.red.asHex)\(resolved.green.asHex)\(resolved.blue.asHex)"
        } else {
            "#\(resolved.red.asHex)\(resolved.green.asHex)\(resolved.blue.asHex) (\(resolved.opacity.asPercentage) opacity)"
        }
    }
}

private extension Float {
    var asHex: String {
        String(format: "%02X", Int((self * 255).rounded()))
    }
    
    var asPercentage: String {
        String(format: "%.0f%%", self * 100)
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
