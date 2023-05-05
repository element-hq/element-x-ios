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
                
                Toggle(isOn: $context.startChatFlowEnabled) {
                    Text("Show Start Chat flow")
                }
                .onChange(of: context.startChatFlowEnabled) { _ in
                    context.send(viewAction: .changedStartChatFlowEnabled)
                }
                
                Toggle(isOn: $context.startChatUserSuggestionsEnabled) {
                    Text("Start chat user suggestions")
                }
                .onChange(of: context.startChatUserSuggestionsEnabled) { _ in
                    context.send(viewAction: .changedStartChatUserSuggestionsEnabled)
                }
                
                Toggle(isOn: $context.mediaUploadFlowEnabled) {
                    Text("Show Media Uploading flow")
                }
                .onChange(of: context.mediaUploadFlowEnabled) { _ in
                    context.send(viewAction: .changedMediaUploadFlowEnabled)
                }
                
                Toggle(isOn: $context.invitesFlowEnabled) {
                    Text("Show Invites flow")
                }
                .onChange(of: context.invitesFlowEnabled) { _ in
                    context.send(viewAction: .changedInvitesFlowEnabled)
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
        .scrollContentBackground(.hidden)
        .background(Color.element.formBackground.ignoresSafeArea())
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
        let viewModel = DeveloperOptionsScreenViewModel()
        DeveloperOptionsScreen(context: viewModel.context)
    }
}
