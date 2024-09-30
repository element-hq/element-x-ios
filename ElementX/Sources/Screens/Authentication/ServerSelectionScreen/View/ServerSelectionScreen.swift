//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
        .toolbar { toolbar }
        .alert(item: $context.alertInfo)
        .interactiveDismissDisabled()
    }
    
    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(spacing: 8) {
            Image(asset: Asset.Images.serverSelectionIcon)
                .heroImage(insets: 19)
                .padding(.bottom, 8)
            
            Text(L10n.screenChangeServerTitle)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
            
            Text(L10n.screenChangeServerSubtitle)
                .font(.compound.bodyMD)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textSecondary)
        }
        .padding(.horizontal, 16)
    }
    
    /// The text field and confirm button where the user enters a server URL.
    var serverForm: some View {
        VStack(alignment: .leading, spacing: 24) {
            TextField(L10n.commonServerUrl, text: $context.homeserverAddress)
                .textFieldStyle(.authentication(labelText: Text(L10n.screenChangeServerFormHeader),
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
            .buttonStyle(.compound(.primary))
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

struct ServerSelection_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        ForEach(MockServerSelectionScreenState.allCases, id: \.self) { state in
            NavigationStack {
                ServerSelectionScreen(context: state.viewModel.context)
            }
        }
    }
}
