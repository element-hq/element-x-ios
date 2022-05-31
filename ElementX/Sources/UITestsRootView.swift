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
    var selectionCallback: ((String) -> Void)?
    
    var body: some View {
        NavigationView {
            List(mockScreens) { coordinator in
                Button(coordinator.id) {
                    selectionCallback?(coordinator.id)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Screens")
    }
}
