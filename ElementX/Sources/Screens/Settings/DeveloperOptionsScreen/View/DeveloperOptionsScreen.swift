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
            Section {
                Toggle(isOn: $context.shouldCollapseRoomStateEvents) {
                    Text("Collapse room state events")
                }
                .onChange(of: context.shouldCollapseRoomStateEvents) { _ in
                    context.send(viewAction: .changedShouldCollapseRoomStateEvents)
                }
                
                Toggle(isOn: $context.userSuggestionsEnabled) {
                    Text("User suggestions")
                }
                .onChange(of: context.userSuggestionsEnabled) { _ in
                    context.send(viewAction: .changedUserSuggestionsEnabled)
                }

                Toggle(isOn: $context.readReceiptsEnabled) {
                    Text("Show read receipts")
                    Text("requires app reboot")
                }
                .onChange(of: context.readReceiptsEnabled) { _ in
                    context.send(viewAction: .changedReadReceiptsEnabled)
                }

                Toggle(isOn: $context.isEncryptionSyncEnabled) {
                    Text("Use notification encryption sync")
                    Text("requires app reboot")
                }
                .onChange(of: context.isEncryptionSyncEnabled) { _ in
                    context.send(viewAction: .changedIsEncryptionSyncEnabled)
                }

                Toggle(isOn: $context.locationEventsEnabled) {
                    Text("Location events in timeline")
                }
                .onChange(of: context.locationEventsEnabled) { _ in
                    context.send(viewAction: .changedLocationEventsEnabled)
                }
                
                Toggle(isOn: $context.shareLocationEnabled) {
                    Text("Show share location action")
                }
                .onChange(of: context.shareLocationEnabled) { _ in
                    context.send(viewAction: .changedShareLocationEnabled)
                }
                
                Toggle(isOn: $context.notificationSettingsEnabled) {
                    Text("Show notification settings")
                }
                .onChange(of: context.notificationSettingsEnabled) { _ in
                    context.send(viewAction: .changedNotificationSettingsEnabled)
                }
            }
            
            Section {
                Button {
                    showConfetti = true
                } label: {
                    Text("🥳")
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
    static var previews: some View {
        let viewModel = DeveloperOptionsScreenViewModel(appSettings: ServiceLocator.shared.settings)
        DeveloperOptionsScreen(context: viewModel.context)
    }
}
