//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct SidebarList: View {
    var body: some View {
        List {
            tokensSection
            componentsSection
            systemComponentsSection
        }
        .navigationTitle("Components")
        .listStyle(.sidebar)
        .tint(.compound.iconAccentTertiary)
    }
    
    var tokensSection: some View {
        Section("Tokens") {
            NavigationLink(value: Screen.colors) {
                Label("Colours", systemImage: "paintpalette")
            }
            NavigationLink(value: Screen.gradients) {
                Label("Gradients", systemImage: "lightspectrum.horizontal")
            }
            NavigationLink(value: Screen.fonts) {
                Label("Typography", systemImage: "character")
            }
            NavigationLink(value: Screen.icons) {
                Label("Icons", systemImage: "pencil.and.outline")
            }
        }
    }
    
    var componentsSection: some View {
        Section("Components") {
            NavigationLink(value: Screen.buttons) {
                Label("Buttons", systemImage: "rectangle.and.hand.point.up.left")
            }
            NavigationLink(value: Screen.list) {
                Label("List", systemImage: "list.bullet.clipboard")
            }
            NavigationLink(value: Screen.bigIcon) {
                Label("Big Icon", systemImage: "square.dashed")
            }
            NavigationLink(value: Screen.titleAndIcon) {
                Label("Title & Icon", systemImage: "richtext.page")
            }
        }
    }
    
    var systemComponentsSection: some View {
        Section("System Components") {
            NavigationLink(value: Screen.actionSheet) {
                Label("Action Sheets", systemImage: "window.shade.closed")
            }
            
            NavigationLink(value: Screen.alert) {
                Label("Alerts", systemImage: "exclamationmark.triangle")
            }
            
            NavigationLink(value: Screen.contextMenu) {
                Label("Context Menus", systemImage: "contextualmenu.and.cursorarrow")
            }
            
            NavigationLink(value: Screen.navigationBar) {
                Label("Navigation Bar", systemImage: "window.shade.open")
            }
            
            NavigationLink(value: Screen.shareSheet) {
                Label("Share Sheet", systemImage: "square.and.arrow.up")
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            SidebarList()
        }
    }
}
