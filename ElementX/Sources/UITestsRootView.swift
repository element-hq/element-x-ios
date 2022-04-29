//
//  UITestsRootView.swift
//  ElementX
//
//  Created by Stefan Ceriu on 29/04/2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import SwiftUI

struct UITestsRootView: View {
    
    let mockCoordinators: [MockScreens]
    var selectionCallback: ((String) -> Void)?
    
    var body: some View {
        NavigationView {
            List(mockCoordinators) { coordinator in
                Button(coordinator.id) {
                    selectionCallback?(coordinator.id)
                }
            }
            .listStyle(.plain)
        }
        .navigationTitle("Screens")
    }
}
