//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct DeveloperOptionsScreen: View {
    @Environment(\.dismiss) private var dismiss
    @State private var showMarkAllRoomsAsReadAlert = false
    
    @Bindable var context: DeveloperOptionsScreenViewModel.Context
    
    @State private var showConfetti = false
    @State private var elementCallURLOverrideString: String
    
    init(context: DeveloperOptionsScreenViewModel.Context) {
        self.context = context
        elementCallURLOverrideString = context.elementCallBaseURLOverride?.absoluteString ?? ""
    }
    
    var body: some View {
        Form {
            if let storeSizes = context.viewState.storeSizes {
                Section("Usage") {
                    ForEach(storeSizes) { storeSize in
                        LabeledContent(storeSize.name, value: storeSize.size)
                    }
                }
            }
            
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
            
            Section("General") {
                Toggle(isOn: $context.linkNewDeviceEnabled) {
                    Text("Link new device with QR code")
                }
                
                context.viewState.appHooks
                    .developerOptionsScreenHook
                    .generalSectionRows()
            }
            
            Section("Room List") {
                Picker("Room list activity visibility", selection: $context.roomListActivityVisibility) {
                    ForEach(RoomListActivityVisibility.allCases, id: \.self) { visibility in
                        Text(visibility.rawValue.capitalized)
                            .tag(visibility)
                    }
                }
                
                Toggle(isOn: $context.fuzzyRoomListSearchEnabled) {
                    Text("Fuzzy searching")
                }
                
                Toggle(isOn: $context.lowPriorityFilterEnabled) {
                    Text("Low priority filter")
                }
                
                Toggle(isOn: $context.automaticBackPaginationEnabled) {
                    Text("Automatic back pagination")
                    Text("Requires app reboot")
                }
            }
            
            Section("Room") {
                Toggle(isOn: $context.roomThreadListEnabled) {
                    Text("Room thread list")
                }
                
                Toggle(isOn: $context.linkPreviewsEnabled) {
                    Text("Link previews")
                    Text("Follows the timeline media visibility settings.")
                    Text("Can leak the device IP address when loading link metadata.")
                        .foregroundStyle(.compound.textCriticalPrimary)
                }

                Toggle(isOn: $context.jumpToReadMarkerEnabled) {
                    Text("Jump to unread")
                    Text("Adds a button to jump to the read marker, plus a presence dot on the scroll-to-bottom button when new messages arrive while scrolled away.")
                }

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

            Section("Element Call remote URL override") {
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
            }
            
            Section("Notifications") {
                Toggle(isOn: $context.hideQuietNotificationAlerts) {
                    Text("Hide quiet alerts")
                    Text("The badge count will still be updated")
                }
                
                Toggle(isOn: $context.focusEventOnNotificationTap) {
                    Text("Focus event on notification tap")
                }
            }
            
            Section {
                Button {
                    showMarkAllRoomsAsReadAlert = true
                } label: {
                    Text("Mark all rooms as read")
                }.alert("Are you sure you want to mark all the rooms as read?", isPresented: $showMarkAllRoomsAsReadAlert) {
                    Button("Cancel", role: .cancel) { }
                    
                    Button("Yes") {
                        context.send(viewAction: .markAllRoomsAsRead)
                    }
                }
            } footer: {
                Text("""
                This will send a private read receipt and a read marker in every room you are part of. \ 
                It's a long running operation that might get rate limited. \
                It will run in the background but the app must be alive for it to finish.
                """)
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
            
            if context.viewState.shouldShowClearCache {
                Section {
                    Button(role: .destructive) {
                        context.send(viewAction: .clearCache)
                    } label: {
                        Text("Clear cache")
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .overlay(effectsView)
        .navigationTitle(L10n.commonDeveloperOptions)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
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
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        if context.viewState.isPresentedModally {
            ToolbarItem(placement: .primaryAction) {
                if #available(iOS 26.0, *) {
                    Button(role: .close, action: dismiss.callAsFunction)
                } else {
                    Button(L10n.actionDone, action: dismiss.callAsFunction)
                }
            }
        }
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
    static let viewModel = DeveloperOptionsScreenViewModel(developerOptions: AppSettings.volatile(),
                                                           elementCallBaseURL: AppSettings.volatile().elementCallBaseURL,
                                                           appHooks: AppHooks(),
                                                           clientProxy: ClientProxyMock(.init()))
    
    static var previews: some View {
        ElementNavigationStack {
            DeveloperOptionsScreen(context: viewModel.context)
        }
    }
}
