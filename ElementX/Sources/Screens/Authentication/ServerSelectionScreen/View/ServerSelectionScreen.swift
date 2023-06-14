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

struct ServerSelectionScreen: View {
    @ObservedObject var context: ServerSelectionScreenViewModel.Context
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, UIConstants.iconTopPaddingToNavigationBar)
                    .padding(.bottom, 36)
                
                serverForm
            }
            .readableFrame()
            .padding(.horizontal, 16)
        }
        .background(Color.element.background.ignoresSafeArea())
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
        .interactiveDismissDisabled()
    }
    
    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(spacing: 8) {
            AuthenticationIconImage(image: Image(asset: Asset.Images.serverSelectionIcon), insets: 19)
                .padding(.bottom, 8)
            
            Text(L10n.commonSelectYourServer)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(L10n.screenChangeServerSubtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.element.tertiaryContent)
        }
        .padding(.horizontal, 16)
    }
    
    /// The text field and confirm button where the user enters a server URL.
    var serverForm: some View {
        VStack(alignment: .leading, spacing: 24) {
            TextField(L10n.commonServerUrl, text: $context.homeserverAddress)
                .textFieldStyle(.elementInput(labelText: Text(L10n.screenChangeServerFormHeader),
                                              footerText: Text(context.viewState.footerMessage),
                                              isError: context.viewState.isShowingFooterError,
                                              accessibilityIdentifier: A11yIdentifiers.changeServerScreen.server))
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: context.homeserverAddress) { _ in context.send(viewAction: .clearFooterError) }
                .submitLabel(.done)
                .onSubmit(submit)
            
            Button(action: submit) {
                Text(context.viewState.buttonTitle)
            }
            .buttonStyle(.elementAction(.xLarge))
            .disabled(context.viewState.hasValidationError)
            .accessibilityIdentifier(A11yIdentifiers.changeServerScreen.continue)
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if context.viewState.isModallyPresented {
                Button { context.send(viewAction: .dismiss) } label: {
                    Text(L10n.actionCancel)
                }
                .accessibilityIdentifier(A11yIdentifiers.changeServerScreen.dismiss)
            }
        }
    }
    
    /// Sends the `confirm` view action so long as the text field input is valid.
    func submit() {
        guard !context.viewState.hasValidationError else { return }
        context.send(viewAction: .confirm)
    }
}

// MARK: - Previews

struct ServerSelection_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(MockServerSelectionScreenState.allCases, id: \.self) { state in
            NavigationStack {
                ServerSelectionScreen(context: state.viewModel.context)
            }
        }
    }
}
