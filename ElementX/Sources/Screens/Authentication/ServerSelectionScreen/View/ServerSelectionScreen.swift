//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ServerSelectionScreen: View {
    @Bindable var context: ServerSelectionScreenViewModel.Context
    
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
            BigIcon(icon: \.host)
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
                .textFieldStyle(.element(labelText: Text(L10n.screenChangeServerFormHeader),
                                         footerText: Text(context.viewState.footerMessage),
                                         state: context.viewState.isShowingFooterError ? .error : .default,
                                         accessibilityIdentifier: A11yIdentifiers.changeServerScreen.server))
                .keyboardType(.URL)
                .autocapitalization(.none)
                .disableAutocorrection(true)
                .onChange(of: context.homeserverAddress) { context.send(viewAction: .clearFooterError) }
                .submitLabel(.done)
                .onSubmit(submit)
            
            Button(action: submit) {
                Text(L10n.actionContinue)
            }
            .buttonStyle(.compound(.primary))
            .disabled(context.viewState.hasValidationError)
            .accessibilityIdentifier(A11yIdentifiers.changeServerScreen.continue)
        }
    }
    
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { context.send(viewAction: .dismiss) } label: {
                Text(L10n.actionCancel)
            }
            .accessibilityIdentifier(A11yIdentifiers.changeServerScreen.dismiss)
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
    static let matrixViewModel = makeViewModel(for: "https://matrix.org")
    static let emptyViewModel = makeViewModel(for: "")
    static let invalidViewModel = makeViewModel(for: "thisisbad")
    
    static var previews: some View {
        NavigationStack {
            ServerSelectionScreen(context: matrixViewModel.context)
        }
        
        NavigationStack {
            ServerSelectionScreen(context: emptyViewModel.context)
        }
        
        NavigationStack {
            ServerSelectionScreen(context: invalidViewModel.context)
        }
        .snapshotPreferences(expect: invalidViewModel.context.observe(\.viewState.hasValidationError))
    }
    
    static func makeViewModel(for homeserverAddress: String) -> ServerSelectionScreenViewModel {
        let authenticationService = AuthenticationService.mock
        
        let viewModel = ServerSelectionScreenViewModel(authenticationService: authenticationService,
                                                       authenticationFlow: .login,
                                                       appSettings: ServiceLocator.shared.settings,
                                                       userIndicatorController: UserIndicatorControllerMock())
        viewModel.context.homeserverAddress = homeserverAddress
        if homeserverAddress == "thisisbad" {
            viewModel.context.send(viewAction: .confirm)
        }
        return viewModel
    }
}
