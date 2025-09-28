//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Compound

struct AlertScreen: View {
    @State private var isPresentingActionAlert = false
    @State private var isPresentingActionAndCancelAlert = false
    @State private var isPresentingDestructiveAlert = false
    @State private var isPresentingTextFieldAlert = false
    @State private var textFieldValue = ""
    
    private let title = "A Short Title is Best"
    private let message = "A message should be a short, complete sentence."
    
    var body: some View {
        ScreenContent(navigationTitle: "Alerts") {
            Text("This component will be rendered differently when running on macOS.")
                .font(.footnote)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Button("Action") { isPresentingActionAlert = true }
                .padding(.top)
                .alert(title, isPresented: $isPresentingActionAlert) {
                    Button("Action") { }
                } message: {
                    Text(message)
                }
            
            Button("Action and Cancel") { isPresentingActionAndCancelAlert = true }
                .padding(.top)
                .alert(title, isPresented: $isPresentingActionAndCancelAlert) {
                    Button("Action") { }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text(message)
                }
            
            Button("Destructive") { isPresentingDestructiveAlert = true }
                .padding(.top)
                .alert(title, isPresented: $isPresentingDestructiveAlert) {
                    Button("Action") { }
                    Button("Destructive", role: .destructive) { }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text(message)
                }
            
            Button("TextField") { isPresentingTextFieldAlert = true }
                .padding(.top)
                .alert(title, isPresented: $isPresentingTextFieldAlert) {
                    TextField("Input", text: $textFieldValue, prompt: Text("Placeholder"))
                    Button("Action") { }
                    Button("Cancel", role: .cancel) { }
                } message: {
                    Text(message)
                }
        }
    }
}

struct AlertScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            AlertScreen()
        }
        .introspect(.window, on: .supportedVersions) { window in
            // Fix the tint colour like the App strut does.
            window.tintColor = .compound.textActionPrimary
        }
        .previewLayout(.fixed(width: 375, height: 750))
    }
}
