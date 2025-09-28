//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Compound
import HyperionCore

@main
struct CompoundInspectorApp: App {
    @State private var colorScheme: ColorScheme = .light
    @State private var dynamicTypeSize: DynamicTypeSize = .large
    
    private var isDark: Bool { colorScheme == .dark }
    private var preferredColorScheme: ColorScheme? { ProcessInfo.processInfo.isMacCatalystApp ? colorScheme : nil }
    
    var body: some Scene {
        WindowGroup {
            NavigationSplitView {
                SidebarList()
                    .navigationTitle("Components")
                    .navigationDestination(for: Screen.self) { screen in
                        screen
                            #if targetEnvironment(macCatalyst)
                            .dynamicTypeSize(dynamicTypeSize)
                            #endif
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar { screenToolbar }
                    }
            } detail: {
                EmptyView()
            }
            .accentColor(.compound.textActionPrimary)
            .preferredColorScheme(preferredColorScheme)
            .introspect(.window, on: .supportedVersions) { window in
                // Apply the tint colour to alerts and confirmation dialogs
                window.tintColor = .compound.textActionPrimary
            }
        }
        .commands {
            CommandMenu("Options") {
                Button("Hyperion", action: HyperionManager.sharedInstance().togglePluginDrawer)
                    .keyboardShortcut("i", modifiers: [.command, .option])
                
                Divider()
                
                Button("Toggle Appearance", action: toggleDarkMode)
                    .keyboardShortcut("a", modifiers: [.command, .shift])
                
                #if targetEnvironment(macCatalyst)
                textSizePicker
                #endif
            }
        }
    }
    
    var textSizePicker: some View {
        Picker("Text Size", selection: $dynamicTypeSize) {
            ForEach(DynamicTypeSize.allCases, id: \.self) { size in
                Text(String(describing: size)).tag(size)
            }
        }
    }
    
    @ViewBuilder
    var screenToolbar: some View {
        #if targetEnvironment(macCatalyst)
        Menu {
            textSizePicker
                .pickerStyle(.inline)
        } label: {
            Image(systemName: "textformat.size")
        }
        #endif

        Button(action: HyperionManager.sharedInstance().togglePluginDrawer) {
            Image(systemName: "ruler")
        }
    }
    
    func toggleDarkMode() {
        colorScheme = isDark ? .light : .dark
    }
}
