//
// Copyright 2022 New Vector Ltd
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

struct DeveloperOptionsScreen: View {
    @ObservedObject var context: DeveloperOptionsScreenViewModel.Context
    @State private var showConfetti = false

    var body: some View {
        Form {
            Section("Logging") {
                Picker(selection: $context.logLevel) {
                    ForEach(TracingConfiguration.LogLevel.allCases, id: \.self) { logLevel in
                        Text(logLevel.rawValue.capitalized)
                    }
                } label: {
                    Text("Log level")
                    Text("Requires app reboot")
                }
                
                Toggle(isOn: $context.otlpTracingEnabled) {
                    Text("OTLP tracing")
                    Text("Requires app reboot")
                }
            }
            
            Section("Timeline") {
                Toggle(isOn: $context.shouldCollapseRoomStateEvents) {
                    Text("Collapse room state events")
                }
                
                Toggle(isOn: $context.readReceiptsEnabled) {
                    Text("Show read receipts")
                    Text("Requires app reboot")
                }

                Toggle(isOn: $context.swiftUITimelineEnabled) {
                    Text("SwiftUI Timeline")
                    Text("Resets on reboot")
                }
            }
            
            Section("Notifications") {
                Toggle(isOn: $context.notificationSettingsEnabled) {
                    Text("Show notification settings")
                }
            }

            Section("Room creation") {
                Toggle(isOn: $context.userSuggestionsEnabled) {
                    Text("User suggestions")
                }
            }

            Section("Polls") {
                Toggle(isOn: $context.pollsInTimelineEnabled) {
                    Text("View polls in timeline")
                }
            }

            Section("Rich Text Editor") {
                Toggle(isOn: $context.richTextEditorEnabled) {
                    Text("Use the Rich Text Editor")
                }
            }

            Section {
                Button {
                    showConfetti = true
                } label: {
                    Text("🥳")
                        .frame(maxWidth: .infinity)
                        .alignmentGuide(.listRowSeparatorLeading) { _ in 0 } // Fix separator alignment
                }
                
                Button {
                    fatalError("This crash is a test.")
                } label: {
                    Text("💥")
                        .frame(maxWidth: .infinity)
                }
            }

            Section {
                Button(role: .destructive) {
                    context.send(viewAction: .clearCache)
                } label: {
                    Text("Clear cache")
                        .frame(maxWidth: .infinity)
                }
            }
        }
        .overlay(effectsView)
        .compoundForm()
        .navigationTitle(L10n.commonDeveloperOptions)
        .navigationBarTitleDisplayMode(.inline)
    }

    @ViewBuilder
    private var effectsView: some View {
        if showConfetti {
            EffectsView(effect: .confetti)
                .ignoresSafeArea()
                .allowsHitTesting(false)
                .task { await removeConfettiAfterDelay() }
        }
    }

    private func removeConfettiAfterDelay() async {
        try? await Task.sleep(for: .seconds(4))
        showConfetti = false
    }
}

// MARK: - Previews

struct DeveloperOptionsScreen_Previews: PreviewProvider {
    static let viewModel = DeveloperOptionsScreenViewModel(developerOptions: ServiceLocator.shared.settings)
    static var previews: some View {
        NavigationStack {
            DeveloperOptionsScreen(context: viewModel.context)
        }
    }
}
