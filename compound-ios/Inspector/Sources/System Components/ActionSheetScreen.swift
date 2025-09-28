//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Compound

struct ActionSheetScreen: View {
    @State private var isPresentingConfirmationDialog = true
    
    var body: some View {
        ScreenContent(navigationTitle: "Action Sheets") {
            Text("This component will be rendered differently when running on macOS.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .toolbar {
            ToolbarItem(placement: .bottomBar) {
                Button("Show Sheet") {
                    isPresentingConfirmationDialog = true
                }
                .confirmationDialog("A Short Title is Best",
                                    isPresented: $isPresentingConfirmationDialog) {
                    Button("Default") { }
                    Button("Default") { }
                    Button("Default") { }
                    Button("Disabled") { }
                        .disabled(true) // This hides the button on iOS 16 😐
                    Button("Destructive", role: .destructive) { }
                } message: {
                    Text("A message should be a short, complete sentence.")
                }
            }
        }
    }
}

struct ActionSheetScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            ActionSheetScreen()
        }
        .introspect(.window, on: .supportedVersions) { window in
            // Fix the tint colour like the App strut does.
            window.tintColor = .compound.textActionPrimary
        }
        .previewLayout(.fixed(width: 375, height: 750))
    }
}
