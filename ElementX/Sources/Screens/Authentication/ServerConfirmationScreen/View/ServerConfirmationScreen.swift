//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ServerConfirmationScreen: View {
    @Bindable var context: ServerConfirmationScreenViewModel.Context
    
    private var backgroundColor: Color {
        switch context.viewState.mode {
        case .confirmation: .compound.bgCanvasDefault
        case .picker: .compound.bgSubtleSecondaryLevel0
        }
    }
    
    private var headerIcon: KeyPath<CompoundIcons, Image> {
        switch context.viewState.mode {
        case .confirmation: \.userProfileSolid
        case .picker: \.homeSolid
        }
    }
    
    private var headerIconStyle: BigIcon.Style {
        switch context.viewState.mode {
        case .confirmation: .defaultSolid
        case .picker: .default
        }
    }
    
    var body: some View {
        FullscreenDialog(topPadding: UIConstants.iconTopPaddingToNavigationBar) {
            VStack(spacing: 36) {
                header
                mainContent
            }
        } bottomContent: {
            buttons
        }
        .background()
        .backgroundStyle(backgroundColor)
        .alert(item: $context.alertInfo)
        .introspect(.window, on: .supportedVersions) { window in
            context.send(viewAction: .updateWindow(window))
        }
    }
    
    /// The main content of the view to be shown in a scroll view.
    var header: some View {
        VStack(spacing: 8) {
            BigIcon(icon: headerIcon, style: headerIconStyle)
                .padding(.bottom, 8)
            
            Text(context.viewState.title)
                .font(.compound.headingMDBold)
                .multilineTextAlignment(.center)
                .foregroundColor(.compound.textPrimary)
                .fixedSize(horizontal: false, vertical: true)
            
            if let message = context.viewState.message {
                Text(message)
                    .font(.compound.bodyMD)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.compound.textSecondary)
            }
        }
        .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    var mainContent: some View {
        if case .picker(let accountProviders) = context.viewState.mode {
            FakeInlinePicker(items: accountProviders,
                             icon: \.host,
                             selection: $context.pickerSelection)
                .accessibilityIdentifier(A11yIdentifiers.serverConfirmationScreen.serverPicker)
        }
    }
    
    /// The action buttons shown at the bottom of the view.
    var buttons: some View {
        VStack(spacing: 16) {
            Button { context.send(viewAction: .confirm) } label: {
                Text(L10n.actionContinue)
            }
            .buttonStyle(.compound(.primary))
            .accessibilityIdentifier(A11yIdentifiers.serverConfirmationScreen.continue)
            
            if case .confirmation = context.viewState.mode {
                Button { context.send(viewAction: .changeServer) } label: {
                    Text(L10n.screenServerConfirmationChangeServer)
                        .font(.compound.bodyLGSemibold)
                        .padding(14)
                }
                .accessibilityIdentifier(A11yIdentifiers.serverConfirmationScreen.changeServer)
            }
        }
    }
}

/// This is such a hack. I hate it!
/// But… We're not in a List/Form, the compound picker doesn't
/// support icons and this screen's design might change so 🤷‍♂️.
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

struct ServerConfirmationScreen_Previews: PreviewProvider, TestablePreview {
    static let loginViewModel = makeViewModel(mode: .confirmation("matrix.org"), flow: .login)
    static let registerViewModel = makeViewModel(mode: .confirmation("matrix.org"), flow: .register)
    static let pickerViewModel = makeViewModel(mode: .picker(["dept1.company.com", "dept2.company.com", "dept3.company.com"]), flow: .login)
    
    static var previews: some View {
        NavigationStack {
            ServerConfirmationScreen(context: loginViewModel.context)
                .toolbar(.visible, for: .navigationBar)
        }
        .previewDisplayName("Login")
        
        NavigationStack {
            ServerConfirmationScreen(context: registerViewModel.context)
                .toolbar(.visible, for: .navigationBar)
        }
        .previewDisplayName("Register")
        
        NavigationStack {
            ServerConfirmationScreen(context: pickerViewModel.context)
                .toolbar(.visible, for: .navigationBar)
        }
        .previewDisplayName("Picker")
    }
    
    static func makeViewModel(mode: ServerConfirmationScreenMode, flow: AuthenticationFlow) -> ServerConfirmationScreenViewModel {
        ServerConfirmationScreenViewModel(authenticationService: AuthenticationService.mock,
                                          mode: mode,
                                          authenticationFlow: flow,
                                          appSettings: ServiceLocator.shared.settings,
                                          userIndicatorController: UserIndicatorControllerMock())
    }
}
