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

struct InvitesListScreen: View {
    @Environment(\.colorScheme) private var colorScheme
    
    var counterColor: Color {
        colorScheme == .light ? .element.secondaryContent : .element.tertiaryContent
    }
    
    @ObservedObject var context: InvitesListViewModel.Context
    
    var body: some View {
        ScrollView {
            mainContent
                .padding(.top, 50)
                .padding(.horizontal)
                .readableFrame()
        }
        .safeAreaInset(edge: .bottom) {
            buttons
                .padding(.horizontal)
                .padding(.vertical)
                .readableFrame()
                .background(Color.element.system)
        }
    }
    
    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(spacing: 36) {
            Text(context.viewState.promptType.title)
                .font(.element.title2Bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.element.primaryContent)
                .accessibilityIdentifier("title")
            
            Image(systemName: context.viewState.promptType.imageSystemName)
                .resizable()
                .scaledToFit()
                .frame(width: 100)
            
            HStack {
                Text("Counter: \(context.viewState.count)")
                    .font(.element.body)
                    .multilineTextAlignment(.center)
                    .foregroundColor(counterColor)
                
                Button("−") {
                    context.send(viewAction: .decrementCount)
                }
                .buttonStyle(.elementGhost())
                
                Button("+") {
                    context.send(viewAction: .incrementCount)
                }
                .buttonStyle(.elementGhost())
            }
        }
    }
    
    /// The action buttons shown at the bottom of the view.
    var buttons: some View {
        VStack {
            Button { context.send(viewAction: .accept) } label: {
                Text("Accept")
            }
            .buttonStyle(.elementAction(.xLarge))
            
            Button { context.send(viewAction: .cancel) } label: {
                Text("Cancel")
                    .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Previews

struct InvitesList_Previews: PreviewProvider {
    static let regularViewModel = InvitesListViewModel(promptType: .regular)
    static let upgradeViewModel = InvitesListViewModel(promptType: .upgrade)
    static var previews: some View {
        InvitesListScreen(context: regularViewModel.context)
            .previewDisplayName("Regular")
        InvitesListScreen(context: upgradeViewModel.context)
            .previewDisplayName("Upgrade")
    }
}
