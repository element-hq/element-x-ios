//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Compound

struct NavigationBarScreen: View {
    enum TitleMode {
        case large
        case inline
        case hidden
    }
    
    enum BackButtonMode {
        case navigation
        case cancellationAction
        case hidden
    }
    
    @State private var titleMode = TitleMode.inline
    @State private var backButtonMode = BackButtonMode.navigation
    @State private var hasConfirmationAction = true
    @State private var hasPrimaryAction = false
    
    var body: some View {
        Form {
            Section {
                ListRow(kind: .custom {
                    Text("This component may be rendered differently when running on macOS.")
                        .font(.compound.bodySM)
                        .foregroundColor(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity)
                        .listRowBackground(Color.clear)
                })
            }
            
            Section {
                ListRow(label: .plain(title: "Title"),
                        kind: .picker(selection: $titleMode, items: [
                                        (title: "Large", tag: .large),
                                        (title: "Inline", tag: .inline),
                                        (title: "Hidden", tag: .hidden)
                                      ]))
                ListRow(label: .plain(title: "Back Button"),
                        kind: .picker(selection: $backButtonMode, items: [
                                        (title: "Navigation", tag: .navigation),
                                        (title: "Cancelation Action", tag: .cancellationAction),
                                        (title: "Hidden", tag: .hidden)
                                      ]))
                
                ListRow(label: .plain(title: "Confirmation Action"),
                        kind: .toggle($hasConfirmationAction))
                ListRow(label: .plain(title: "Primary Action"),
                        kind: .toggle($hasPrimaryAction))
            } header: {
                Text("Configuration")
                    .compoundListSectionHeader()
            }
            
            Section {
                ListRow(kind: .custom {
                    VStack {
                        Text("Empty section to make the form scrollable")
                            .font(.compound.bodySM)
                            .foregroundColor(.compound.textSecondary)
                        Spacer(minLength: 500)
                    }
                    .padding(ListRowPadding.insets)
                })
            }
        }
        .compoundList()
        .navigationTitle(titleMode == .hidden ? "" : "Navigation Bar")
        .navigationBarTitleDisplayMode(titleMode == .large ? .large : .inline)
        .navigationBarBackButtonHidden(backButtonMode != .navigation)
        .toolbar {
            if hasConfirmationAction {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Confirm") { }
                }
            }
            
            if hasPrimaryAction {
                ToolbarItem(placement: .primaryAction) {
                    Button("Primary") { }
                }
            }
            
            if backButtonMode == .cancellationAction {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { }
                }
            }
        }
    }
}

struct NavigationBarScreen_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            NavigationBarScreen()
        }
        .previewLayout(.fixed(width: 375, height: 750))
    }
}
