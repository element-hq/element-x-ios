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

struct DeveloperOptionsScreenScreen: View {
    @ObservedObject var context: DeveloperOptionsScreenViewModel.Context
    @State private var showConfetti = false
    
    var body: some View {
        Form {
            Section {
                Button {
                    showConfetti = true
                } label: {
                    Text("🥳")
                        .frame(maxWidth: .infinity)
                }
            }
            .listRowBackground(Color.element.formRowBackground)
        }
        .overlay(effectsView)
        .scrollContentBackground(.hidden)
        .background(Color.element.formBackground.ignoresSafeArea())
        .navigationTitle(ElementL10n.settingsDeveloperOptions)
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var effectsView: some View {
        if showConfetti {
            EffectsView(effect: .confetti)
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
        DeveloperOptionsScreenScreen(context: viewModel.context)
            .tint(.element.accent)
    }
}
