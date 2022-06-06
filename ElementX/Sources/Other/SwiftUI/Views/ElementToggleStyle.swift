//
//  ElementToggleStyle.swift
//  ElementX
//
//  Created by Ismail on 2.06.2022.
//  Copyright © 2022 Element. All rights reserved.
//

import SwiftUI

/// A toggle style that uses a button, with a checked/unchecked image like a checkbox.
struct ElementToggleStyle: ToggleStyle {

    func makeBody(configuration: Configuration) -> some View {
        Button { configuration.isOn.toggle() } label: {
            Image(systemName: configuration.isOn ? "checkmark.square.fill" : "square")
                .font(.title3.weight(.regular))
                .imageScale(.large)
                .foregroundColor(Color(uiColor: Asset.Colors.elementGreen.color))
        }
        .buttonStyle(.plain)
    }
}
