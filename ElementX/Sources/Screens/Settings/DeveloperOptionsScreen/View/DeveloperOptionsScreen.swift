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
            
            Section("Message Pinning") {
                Toggle(isOn: $context.pinningEnabled) {
                    Text("Enable message pinning")
                    Text("Requires app reboot")
                }
            }
            
            Section("Room List") {
                Toggle(isOn: $context.hideUnreadMessagesBadge) {
                    Text("Hide grey dots")
                }
                
                Toggle(isOn: $context.fuzzyRoomListSearchEnabled) {
                    Text("Fuzzy searching")
                }
            }
            
            Section {
                Toggle(isOn: $context.invisibleCryptoEnabled) {
                    Text("Enabled Invisible Crypto")
                    Text("Requires app reboot")
                }
            } header: {
                Text("Trust and Decoration")
            } footer: {
                Text("This setting controls how end-to-end encryption (E2EE) keys are shared. Enabling it will prevent the inclusion of devices that have not been explicitly verified by their owners.")
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
    static let viewModel = DeveloperOptionsScreenViewModel(developerOptions: ServiceLocator.shared.settings,
                                                           elementCallBaseURL: ServiceLocator.shared.settings.elementCallBaseURL,
                                                           isUsingNativeSlidingSync: true)
    static var previews: some View {
        NavigationStack {
            DeveloperOptionsScreen(context: viewModel.context)
        }
    }
}
