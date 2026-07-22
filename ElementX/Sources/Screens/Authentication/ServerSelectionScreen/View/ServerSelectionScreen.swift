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
        .alert(item: $context.alertInfo)
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
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
    
    /// The main input and confirm button.
    var serverForm: some View {
        VStack(alignment: .leading, spacing: 24) {
            switch context.viewState.mode {
            case .confirmation:
                TextField(L10n.commonServerUrl, text: $context.homeserverAddress)
                    .textFieldStyle(.compound(labelText: Text(L10n.screenChangeServerFormHeader),
                                              footerText: Text(context.viewState.footerMessage),
                                              state: context.viewState.isShowingFooterError ? .error : .default,
                                              accessibilityIdentifier: A11yIdentifiers.changeServerScreen.server))
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .onChange(of: context.homeserverAddress) { context.send(viewAction: .clearFooterError) }
                    .submitLabel(.done)
                    .onSubmit(submit)
            case .picker(let providers):
                FakeInlinePicker(items: providers,
                                 icon: \.host,
                                 selection: $context.pickerSelection)
                    .accessibilityIdentifier(A11yIdentifiers.serverConfirmationScreen.serverPicker)
            }
            
            Button(action: submit) {
                Text(L10n.actionContinue)
            }
            .buttonStyle(.compound(.primary))
            .disabled(context.viewState.hasValidationError)
            .accessibilityIdentifier(A11yIdentifiers.changeServerScreen.continue)
        }
    }
    
    /// Sends the `confirm` view action so long as the text field input is valid.
    func submit() {
        guard !context.viewState.hasValidationError else { return }
        context.send(viewAction: .confirm)
    }
}

// MARK: - Private

private struct FakeInlinePicker: View {
    let items: [String]
    let icon: KeyPath<CompoundIcons, Image>
    @Binding var selection: String?
    
    var body: some View {
        VStack(spacing: 0) {
            ForEach(items, id: \.self) { item in
                ListRow(label: .default(title: item, icon: icon),
                        kind: .selection(isSelected: selection == item) {
                            selection = item
                        })
                        .overlay(alignment: .bottom) {
                            if item != items.last {
                                Divider()
                                    .hidden()
                                    .overlay(Color.compound._borderInteractiveSecondaryAlpha)
                                    .padding(.leading, 54)
                            }
                        }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

// MARK: - Previews

@available(iOS 26.0, *)
struct ServerSelection_Previews: PreviewProvider, TestablePreview {
    static let matrixViewModel = makeViewModel(for: "https://matrix.org")
    static let emptyViewModel = makeViewModel(for: "")
    static let invalidViewModel = makeViewModel(for: "thisisbad")
    static let pickerViewModel = makeViewModel(for: "https://foo.bar", mode: .picker(["matrix.org", "foo.bar", "baz.me"]))
    
    static var previews: some View {
        ElementNavigationStack {
            ServerSelectionScreen(context: matrixViewModel.context)
        }
        .previewDisplayName("Matrix.org")
        
        ElementNavigationStack {
            ServerSelectionScreen(context: emptyViewModel.context)
        }
        .previewDisplayName("Empty")
        
        ElementNavigationStack {
            ServerSelectionScreen(context: invalidViewModel.context)
        }
        .snapshotPreferences(expect: invalidViewModel.context.observe(\.viewState.hasValidationError))
        .previewDisplayName("Error")
        
        ElementNavigationStack {
            ServerSelectionScreen(context: pickerViewModel.context)
        }
        .previewDisplayName("Picker")
    }
    
    static func makeViewModel(for homeserverAddress: String, mode: ServerConfirmationScreenMode = .confirmation("")) -> ServerSelectionScreenViewModel {
        let authenticationService = AuthenticationService.mock
        
        let viewModel = ServerSelectionScreenViewModel(authenticationService: authenticationService,
                                                       mode: mode,
                                                       authenticationFlow: .login,
                                                       appSettings: .volatile(),
                                                       userIndicatorController: UserIndicatorControllerMock())
        viewModel.context.homeserverAddress = homeserverAddress
        if homeserverAddress == "thisisbad" {
            viewModel.context.send(viewAction: .confirm)
        }
        return viewModel
    }
}
