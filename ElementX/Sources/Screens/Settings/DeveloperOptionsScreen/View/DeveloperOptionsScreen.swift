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
    @State private var elementCallBaseURLString = ""
    
    var body: some View {
        Form {
            Section("Logging") {
                LogLevelConfigurationView(logLevel: $context.logLevel)
            }
            
            Section("Room List") {
                Toggle(isOn: $context.hideUnreadMessagesBadge) {
                    Text("Hide grey dots")
                }
                
                Toggle(isOn: $context.fuzzyRoomListSearchEnabled) {
                    Text("Fuzzy searching")
                }
            }
            
            Section("Room") {
                Toggle(isOn: $context.draftRestoringEnabled) {
                    Text("Allow drafts to be restored")
                }
            }
                                    
            Section("Element Call") {
                TextField(context.elementCallBaseURL.absoluteString, text: $elementCallBaseURLString)
                    .submitLabel(.done)
                    .onSubmit {
                        guard let url = URL(string: elementCallBaseURLString) else {
                            return
                        }
                        
                        context.elementCallBaseURL = url
                    }
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
                    .foregroundColor(URL(string: elementCallBaseURLString) == nil ? .red : .primary)
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
        .compoundList()
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

private struct LogLevelConfigurationView: View {
    @Binding var logLevel: TracingConfiguration.LogLevel
    
    @State private var customTracingConfiguration: String

    init(logLevel: Binding<TracingConfiguration.LogLevel>) {
        _logLevel = logLevel
        
        if case .custom(let configuration) = logLevel.wrappedValue {
            customTracingConfiguration = configuration
        } else {
            customTracingConfiguration = TracingConfiguration(logLevel: .info, target: nil).filter
        }
    }
    
    var body: some View {
        Picker(selection: $logLevel) {
            ForEach(logLevels, id: \.self) { logLevel in
                Text(logLevel.title)
            }
        } label: {
            Text("Log level")
            Text("Requires app reboot")
        }
        
        if case .custom = logLevel {
            TextEditor(text: $customTracingConfiguration)
                .textInputAutocapitalization(.never)
                .autocorrectionDisabled()
                .onChange(of: customTracingConfiguration) { newValue in
                    logLevel = .custom(newValue)
                }
        }
    }
    
    /// Allows the picker to work with associated values
    private var logLevels: [TracingConfiguration.LogLevel] {
        if case let .custom(filter) = logLevel {
            return [.error, .warn, .info, .debug, .trace, .custom(filter)]
        } else {
            return [.error, .warn, .info, .debug, .trace, .custom("")]
        }
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
