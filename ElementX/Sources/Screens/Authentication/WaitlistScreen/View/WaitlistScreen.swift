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

struct WaitlistScreen: View {
    @ObservedObject var context: WaitlistScreenViewModel.Context
    
    var body: some View {
        WaitingDialog {
            content
        } bottomContent: {
            buttons
        }
        .navigationBarBackButtonHidden()
        .toolbar { toolbar }
        .overlay {
            EffectsView(effect: context.viewState.isWaiting ? .none : .confetti)
                .ignoresSafeArea()
                .allowsHitTesting(false)
        }
    }
    
    /// The main content of the view to be shown in a scroll view.
    var content: some View {
        VStack(spacing: 16) {
            Text(context.viewState.title.tinting(".", color: .element.brand))
                .font(.compound.headingXLBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            Text(context.viewState.message)
                .font(.compound.bodyLG)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
        }
    }
    
    /// The action buttons shown at the bottom of the view.
    @ViewBuilder
    var buttons: some View {
        if let userSession = context.viewState.userSession {
            Button { context.send(viewAction: .continue(userSession)) } label: {
                Text(L10n.actionContinue)
            }
            .buttonStyle(.elementAction(.xLarge))
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        if context.viewState.isWaiting {
            ToolbarItem(placement: .cancellationAction) {
                Button(L10n.actionCancel) {
                    context.send(viewAction: .cancel)
                }
            }
        }
    }
}

// MARK: - Previews

struct WaitlistScreen_Previews: PreviewProvider {
    static let viewModel = WaitlistScreenViewModel(homeserver: .mockMatrixDotOrg)
    static let successViewModel = {
        let viewModel = WaitlistScreenViewModel(homeserver: .mockMatrixDotOrg)
        viewModel.update(userSession: MockUserSession(clientProxy: MockClientProxy(userID: "@alice:matrix.org"),
                                                      mediaProvider: MockMediaProvider()))
        return viewModel
    }()
    
    static var previews: some View {
        NavigationStack {
            WaitlistScreen(context: viewModel.context)
        }
        .previewDisplayName("Waiting")
        
        NavigationStack {
            WaitlistScreen(context: successViewModel.context)
        }
        .previewDisplayName("Success")
    }
}
