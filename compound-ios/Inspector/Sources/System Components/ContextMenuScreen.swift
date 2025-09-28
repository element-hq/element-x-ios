//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Compound

struct ContextMenuScreen: View {
    var body: some View {
        ScreenContent(navigationTitle: "Context Menus") {
            Text("This component will be rendered differently when running on macOS.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Actions")
                .padding()
                .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 12))
                .contextMenu {
                    Section {
                        Button { } label: {
                            Label("Action", systemImage: "square.dashed")
                        }
                        Button { } label: {
                            Label("Action", systemImage: "square.dashed")
                        }
                        Button { } label: {
                            Label("Disabled", systemImage: "square.dashed")
                        }
                        .disabled(true)
                        Button(role: .destructive) { } label: {
                            Label("Destructive", systemImage: "square.dashed")
                        }
                    }
                    Section {
                        Button { } label: {
                            Label("Action", systemImage: "square.dashed")
                        }
                        Button { } label: {
                            Label("Action", systemImage: "square.dashed")
                        }
                    }
                }
            
            Text("Toggles")
                .padding()
                .contentShape(.contextMenuPreview, RoundedRectangle(cornerRadius: 12))
                .contextMenu {
                    Section {
                        Toggle(isOn: .constant(true)) {
                            Label("Toggle", systemImage: "square.dashed")
                        }
                        Toggle(isOn: .constant(false)) {
                            Label("Toggle", systemImage: "square.dashed")
                        }
                        Toggle(isOn: .constant(false)) {
                            Label("Disabled", systemImage: "square.dashed")
                        }
                        .disabled(true)
                    }
                    Section {
                        Toggle(isOn: .constant(true)) {
                            Label("Toggle", systemImage: "square.dashed")
                        }
                        Toggle(isOn: .constant(true)) {
                            Label("Toggle", systemImage: "square.dashed")
                        }
                    }
                }
        }
    }
}

struct ContextMenuScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ContextMenuScreen()
        }
        .previewLayout(.fixed(width: 375, height: 750))
    }
}
