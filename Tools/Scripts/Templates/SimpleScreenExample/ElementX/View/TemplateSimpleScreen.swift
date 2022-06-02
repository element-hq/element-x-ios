// 
// Copyright 2021 New Vector Ltd
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

struct TemplateSimpleScreen: View {

    // MARK: Private
    
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    
    private var horizontalPadding: CGFloat {
        horizontalSizeClass == .regular ? 50 : 16
    }
    
    // MARK: Public
    
    @ObservedObject var context: TemplateSimpleScreenViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                ScrollView {
                    mainContent
                        .padding(.top, 50)
                        .padding(.horizontal, horizontalPadding)
                }
                
                buttons
                    .padding(.horizontal, horizontalPadding)
                    .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
            }
        }
    }
    
    /// The main content of the view to be shown in a scroll view.
    var mainContent: some View {
        VStack(spacing: 36) {
            Text(context.viewState.promptType.title)
                .accessibilityIdentifier("title")
            
            Image(systemName: context.viewState.promptType.imageSystemName)
                .resizable()
                .scaledToFit()
                .frame(width: 100)
            
            HStack {
                Text("Counter: \(context.viewState.count)")
                
                Button("-") {
                    context.send(viewAction: .decrementCount)
                }
                
                Button("+") {
                    context.send(viewAction: .incrementCount)
                }
            }
        }
    }
    
    /// The action buttons shown at the bottom of the view.
    var buttons: some View {
        VStack {
            Button { context.send(viewAction: .accept) } label: {
                Text("Accept")
            }
            .frame(maxWidth: .infinity)
            
            Button { context.send(viewAction: .cancel) } label: {
                Text("Cancel")
                    .padding(.vertical, 12)
            }
        }
    }
}

// MARK: - Previews

struct TemplateSimpleScreen_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let viewModel = TemplateSimpleScreenViewModel(promptType: .regular)
            TemplateSimpleScreen(context: viewModel.context)
        }
        Group {
            let viewModel = TemplateSimpleScreenViewModel(promptType: .upgrade)
            TemplateSimpleScreen(context: viewModel.context)
        }
    }
}
