//
//  UITestsRootView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 29/04/2022.
//  Copyright © 2022 Element. All rights reserved.
//

import SwiftUI

struct UITestsRootView: View {
    
    let mockScreens: [MockScreen]
    var selectionCallback: ((UITestScreenIdentifier) -> Void)?
    
    var body: some View {
        NavigationView {
            List(mockScreens) { coordinator in
                Button(coordinator.id.description) {
                    selectionCallback?(coordinator.id)
                }
                .accessibilityIdentifier(coordinator.id.rawValue)
            }
            .listStyle(.plain)
        }
        .navigationTitle("Screens")
    }
}
