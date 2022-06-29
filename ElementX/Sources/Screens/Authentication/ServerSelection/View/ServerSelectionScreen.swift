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

struct ServerSelectionScreen: View {

    // MARK: - Properties
    
    // MARK: Private
    
    @FocusState var isTextFieldFocused: Bool
    
    // MARK: Public
    
    @ObservedObject var viewModel: ServerSelectionViewModel.Context
    
    // MARK: Views
    
    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                    .padding(.top, UIConstants.topPaddingToNavigationBar)
                    .padding(.bottom, 36)
                
                serverForm
            }
            .readableFrame()
            .padding(.horizontal, 16)
        }
        .background(Color.element.background, ignoresSafeAreaEdges: .all)
        .toolbar { toolbar }
        .alert(item: $viewModel.alertInfo) { $0.alert }
    }
    
    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(spacing: 8) {
            AuthenticationIconImage(image: Asset.Images.serverSelectionIcon)
                .padding(.bottom, 8)
            
            Text(ElementL10n.serverSelectionTitle)
                .font(.element.title2B)
                .multilineTextAlignment(.center)
                .foregroundColor(.element.primaryContent)
            
            Text(ElementL10n.serverSelectionMessage)
                .font(.element.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.element.secondaryContent)
        }
    }
    
    /// The text field and confirm button where the user enters a server URL.
    var serverForm: some View {
        VStack(alignment: .leading, spacing: 12) {
            TextField(ElementL10n.serverSelectionServerUrl, text: $viewModel.homeserverAddress)
                .focused($isTextFieldFocused)
                .textFieldStyle(.elementInput(footerText: viewModel.viewState.footerMessage,
                                              isError: viewModel.viewState.isShowingFooterError))
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: viewModel.homeserverAddress) { _ in viewModel.send(viewAction: .clearFooterError) }
                .submitLabel(.done)
                .onSubmit(submit)
                .accessibilityIdentifier("addressTextField")
            
            Button(action: submit) {
                Text(viewModel.viewState.buttonTitle)
            }
            .buttonStyle(.elementAction(.xLarge))
            .disabled(viewModel.viewState.hasValidationError)
            .accessibilityIdentifier("confirmButton")
        }
    }
    
    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            if viewModel.viewState.hasModalPresentation {
                Button { viewModel.send(viewAction: .dismiss) } label: {
                    Text(ElementL10n.actionCancel)
                }
                .accessibilityIdentifier("dismissButton")
            }
        }
    }
    
    /// Sends the `confirm` view action so long as the text field input is valid.
    func submit() {
        guard !viewModel.viewState.hasValidationError else { return }
        viewModel.send(viewAction: .confirm)
    }
}

// MARK: - Previews

struct ServerSelection_Previews: PreviewProvider {
    static var previews: some View {
        ForEach(MockServerSelectionScreenState.allCases, id: \.self) { state in
            NavigationView {
                ServerSelectionScreen(viewModel: state.viewModel.context)
                    .tint(.element.accent)
            }
            .navigationViewStyle(.stack)
        }
    }
}
