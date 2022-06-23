// 
// Copyright 2021 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import SwiftUI

struct Settings: View {

    // MARK: Private

    @State private var showingLogoutConfirmation = false
    
    // MARK: Public
    
    @ObservedObject var context: SettingsViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        Form {
            Section {
                Button { context.send(viewAction: .reportBug) } label: {
                    Text(ElementL10n.sendBugReport)
                }
                .listRowBackground(Color.element.system)
                .foregroundColor(Color.element.primaryContent)
                .accessibilityIdentifier("reportBugButton")

                if BuildSettings.settingsCrashButtonVisible {
                    Button("Crash the app",
                           role: .destructive) { context.send(viewAction: .crash)
                    }
                           .listRowBackground(Color.element.system)
                           .accessibilityIdentifier("crashButton")
                }
            }

            Section {
                Button { showingLogoutConfirmation = true } label: {
                    Text(ElementL10n.actionSignOut)
                }
                .listRowBackground(Color.element.system)
                .frame(maxWidth: .infinity)
                .foregroundColor(Color.element.primaryContent)
                .accessibilityIdentifier("logoutButton")
                .confirmationDialog(ElementL10n.actionSignOutConfirmationSimple,
                                    isPresented: $showingLogoutConfirmation,
                                    titleVisibility: .visible) {
                    Button(ElementL10n.actionSignOut,
                           role: .destructive) { context.send(viewAction: .logout)
                    }
                }
            } footer: {
                versionText
            }
        }
        .introspectTableView(customize: { tableView in
            tableView.backgroundColor = .clear
        })
        .navigationTitle(ElementL10n.settings)
        .background(Color.element.background, ignoresSafeAreaEdges: .all)
    }

    var versionText: some View {
        Text(ElementL10n.settingsVersion + ": " + ElementInfoPlist.cfBundleShortVersionString + " (" + ElementInfoPlist.cfBundleVersion + ")")
    }
}

// MARK: - Previews

struct Settings_Previews: PreviewProvider {
    static var previews: some View {
        body.preferredColorScheme(.light)
        body.preferredColorScheme(.dark)
    }

    @ViewBuilder
    static var body: some View {
        let viewModel = SettingsViewModel()
        Settings(context: viewModel.context)
            .previewInterfaceOrientation(.portrait)
    }
}
