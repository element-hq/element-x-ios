//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct DeveloperOptionsScreen: View {
    @Bindable var context: DeveloperOptionsScreenViewModel.Context
    
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
                
                DisclosureGroup("SDK trace packs") {
                    ForEach(TraceLogPack.allCases, id: \.self) { pack in
                        Toggle(isOn: $context.traceLogPacks[pack]) {
                            Text(pack.title)
                        }
                    }
                }
            }
            
            Section("Spaces") {
                Toggle(isOn: $context.spaceSettingsEnabled) {
                    Text("Space settings")
                }
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
                
                Toggle(isOn: $context.lowPriorityFilterEnabled) {
                    Text("Low priority filter")
                }
                
                Toggle(isOn: $context.latestEventSorterEnabled) {
                    Text("Latest event sorter")
                    Text("Requires app reboot")
                }
            }
            
            Section("Timeline") {
                Toggle(isOn: $context.linkPreviewsEnabled) {
                    Text("Link previews")
                    Text("Follows the timeline media visibility settings.")
                    Text("Can leak the device IP address when loading link metadata.")
                        .foregroundStyle(.compound.textCriticalPrimary)
                }
            }
                        
            Section("Join rules") {
                Toggle(isOn: $context.knockingEnabled) {
                    Text("Knocking")
                    Text("Ask to join rooms")
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
                Toggle(isOn: $context.enableKeyShareOnInvite) {
                    Text("Share encrypted history with new members")
                    Text("Requires app reboot")
                }
            } footer: {
                Text("When inviting a user to an encrypted room that has history visibility set to \"shared\", share encrypted history with that user, and accept encrypted history when you are invited to such a room.")
                Text("WARNING: this feature is EXPERIMENTAL and not all security precautions are implemented. Do not enable on production accounts.")
            }

            Section {
                TextField("Leave empty to use EC locally", text: $elementCallURLOverrideString)
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
                Text("Element Call remote URL override")
            }
            
            Section("Notifications") {
                Toggle(isOn: $context.hideQuietNotificationAlerts) {
                    Text("Hide quiet alerts")
                    Text("The badge count will still be updated")
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
    @Binding var logLevel: LogLevel
    
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
    private var logLevels: [LogLevel] {
        [.error, .warn, .info, .debug, .trace]
    }
}

private extension Set<TraceLogPack> {
    /// A custom subscript that allows binding a toggle to add/remove a pack from the array.
    subscript(pack: TraceLogPack) -> Bool {
        get { contains(pack) }
        set {
            if newValue {
                insert(pack)
            } else {
                remove(pack)
            }
        }
    }
}

// MARK: - Previews

struct DeveloperOptionsScreen_Previews: PreviewProvider {
    static let viewModel = DeveloperOptionsScreenViewModel(developerOptions: ServiceLocator.shared.settings,
                                                           elementCallBaseURL: ServiceLocator.shared.settings.elementCallBaseURL)
    static var previews: some View {
        NavigationStack {
            DeveloperOptionsScreen(context: viewModel.context)
        }
    }
}
