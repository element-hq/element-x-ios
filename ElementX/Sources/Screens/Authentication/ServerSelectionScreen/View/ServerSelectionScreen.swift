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
    
    private var backgroundColor: Color {
        switch context.viewState.mode {
        case .userInput: .compound.bgCanvasDefault
        case .picker: .compound.bgSubtleSecondaryLevel0
        }
    }
    
    private var headerIconStyle: BigIcon.Style {
        switch context.viewState.mode {
        case .userInput: .defaultSolid
        case .picker: .default
        }
    }
    
    var body: some View {
        FullscreenDialog {
            VStack(spacing: 0) {
                header
                    .padding(.top, UIConstants.iconTopPaddingToNavigationBar)
                    .padding(.bottom, 36)
                
                serverForm
            }
            .readableFrame()
        } bottomContent: {
            continueButton
        }
        .background(backgroundColor)
        .navigationBarTitleDisplayMode(.inline)
        .navigationTitle(context.viewState.screenTitle)
        .alert(item: $context.alertInfo)
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
    }
    
    /// The title, message and icon at the top of the screen.
    var header: some View {
        VStack(spacing: 8) {
            BigIcon(icon: \.userProfileSolid, style: headerIconStyle)
                .padding(.bottom, 8)
            
            Text(context.viewState.screenHeader)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
        }
        .padding(.horizontal, 16)
    }
    
    /// The main input and confirm button.
    var serverForm: some View {
        VStack(alignment: .leading, spacing: 24) {
            switch context.viewState.mode {
            case .userInput:
                TextField(L10n.commonServerUrl, text: $context.homeserverAddress, selection: $context.homeserverSelection)
                    .textFieldStyle(.compound(labelText: Text(UntranslatedL10n.screenSelectServerTextfieldHeader),
                                              footerText: Text(context.viewState.footerMessage),
                                              state: context.viewState.isShowingFooterError ? .error : .default,
                                              accessibilityIdentifier: A11yIdentifiers.changeServerScreen.server))
                    .keyboardType(.URL)
                    .autocapitalization(.none)
                    .disableAutocorrection(true)
                    .introspect(.textField, on: .supportedVersions) {
                        context.send(viewAction: .updateTextField($0))
                    }
                    .onChange(of: context.homeserverAddress) { context.send(viewAction: .clearFooterError) }
                    .submitLabel(.done)
                    .onSubmit(submit)
            case .picker(let providers):
                FakeInlinePicker(items: providers,
                                 icon: \.host,
                                 selection: $context.homeserverAddress)
                    .accessibilityIdentifier(A11yIdentifiers.serverConfirmationScreen.serverPicker)
            }
        }
    }
    
    private var continueButton: some View {
        Button(action: submit) {
            Text(L10n.actionContinue)
        }
        .buttonStyle(.compound(.primary))
        .disabled(context.viewState.hasValidationError)
        .accessibilityIdentifier(A11yIdentifiers.changeServerScreen.continue)
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
    @Binding var selection: String
    
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
    static let matrixViewModel = makeViewModel(mode: .userInput, server: "matrix.org")
    static let emptyViewModel = makeViewModel(mode: .userInput, server: "")
    static let invalidViewModel = makeViewModel(mode: .userInput, server: "thisisbad")
    static let pickerViewModel = makeViewModel(mode: .picker(["matrix.org", "foo.bar", "baz.me"]), server: "foo.bar")
    
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
    
    static func makeViewModel(mode: ServerSelectionScreenMode = .userInput, server: String) -> ServerSelectionScreenViewModel {
        let authenticationService = AuthenticationService.mock
        
        let viewModel = ServerSelectionScreenViewModel(authenticationService: authenticationService,
                                                       mode: mode,
                                                       authenticationFlow: .login,
                                                       appSettings: .volatile(),
                                                       userIndicatorController: UserIndicatorControllerMock())
        viewModel.context.homeserverAddress = server
        if case .userInput = mode, server == "thisisbad" {
            viewModel.context.send(viewAction: .confirm)
        }
        return viewModel
    }
}
