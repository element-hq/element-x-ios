//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct DeveloperOptionsScreen: View {
    @ObservedObject var context: DeveloperOptionsScreenViewModel.Context
    @State private var showConfetti = false
    @State private var elementCallURLOverrideString: String
    
    init(context: DeveloperOptionsScreenViewModel.Context) {
        self.context = context
        elementCallURLOverrideString = context.elementCallBaseURLOverride?.absoluteString ?? ""
    }
    
    var body: some View {
        Form {
            Section("Logging") {
                LogLevelConfigurationView(logLevel: $context.logLevel)
            }
            
            Section("General") {
                Toggle(isOn: $context.eventCacheEnabled) {
                    Text("Event cache")
                }
                .onChange(of: context.eventCacheEnabled) {
                    context.send(viewAction: .clearCache)
                }
            }
            
            Section {
                Picker("Discovery", selection: $context.slidingSyncDiscovery) {
                    Text("Proxy only").tag(AppSettings.SlidingSyncDiscovery.proxy)
                    Text("Automatic").tag(AppSettings.SlidingSyncDiscovery.native)
                    Text("Force Native ⚠️").tag(AppSettings.SlidingSyncDiscovery.forceNative)
                }
            } header: {
                Text("Sliding Sync")
            } footer: {
                Text(context.viewState.slidingSyncFooter)
            }
            
            Section("Room List") {
                Toggle(isOn: $context.publicSearchEnabled) {
                    Text("Public search")
                }
                
                Toggle(isOn: $context.hideUnreadMessagesBadge) {
                    Text("Hide grey dots")
                }
                
                Toggle(isOn: $context.fuzzyRoomListSearchEnabled) {
                    Text("Fuzzy searching")
                }
            }
            
            Section("Room") {
                Toggle(isOn: $context.hideTimelineMedia) {
                    Text("Hide image & video previews")
                }
            }
            
            Section("Join rules") {
                Toggle(isOn: $context.knockingEnabled) {
                    Text("Knocking")
                    Text("Experimental, still using mocked data")
                }
            }
            
            Section {
                Toggle(isOn: $context.enableOnlySignedDeviceIsolationMode) {
                    Text("Exclude insecure devices when sending/receiving messages")
                    Text("Requires app reboot")
                }
            } header: {
                Text("Trust and Decoration")
            } footer: {
                Text("This setting controls how end-to-end encryption (E2EE) keys are exchanged. Enabling it will prevent the inclusion of devices that have not been explicitly verified by their owners.")
            }

            Section {
                TextField(context.viewState.elementCallBaseURL.absoluteString, text: $elementCallURLOverrideString)
                    .autocorrectionDisabled(true)
                    .autocapitalization(.none)
                    .foregroundColor(URL(string: elementCallURLOverrideString) == nil ? .red : .primary)
                    .submitLabel(.done)
                    .onSubmit {
                        if elementCallURLOverrideString.isEmpty {
                            context.elementCallBaseURLOverride = nil
                        } else if let url = URL(string: elementCallURLOverrideString) {
                            context.elementCallBaseURLOverride = url
                        }
                    }
            } header: {
                Text("Element Call")
            } footer: {
                if context.elementCallBaseURLOverride == nil {
                    Text("The call URL may be overridden by your homeserver.")
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
    
    var body: some View {
        Picker(selection: $logLevel) {
            ForEach(logLevels, id: \.self) { logLevel in
                Text(logLevel.title)
            }
        } label: {
            Text("Log level")
            Text("Requires app reboot")
        }
    }
    
    /// Allows the picker to work with associated values
    private var logLevels: [TracingConfiguration.LogLevel] {
        [.error, .warn, .info, .debug, .trace]
    }
}

// MARK: - Previews

struct DeveloperOptionsScreen_Previews: PreviewProvider {
    static let viewModel = DeveloperOptionsScreenViewModel(developerOptions: ServiceLocator.shared.settings,
                                                           elementCallBaseURL: ServiceLocator.shared.settings.elementCallBaseURL,
                                                           isUsingNativeSlidingSync: true)
    static var previews: some View {
        NavigationStack {
            DeveloperOptionsScreen(context: viewModel.context)
        }
    }
}
