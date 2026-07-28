//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum ServerSelectionScreenViewModelAction {
    /// Continue the flow using the provided OAuth parameters.
    case continueWithOAuth(data: OAuthAuthorizationDataProxy, window: UIWindow)
    /// Continue the flow using password authentication.
    case continueWithPassword
    /// Dismiss the view without using the entered address.
    case dismiss
}

enum ServerSelectionScreenMode: Equatable {
    /// The user is confirming the displayed account provider (or can enter their own).
    case userInput(defaultValue: String)
    /// The user is only allowed to pick from a list of account providers.
    case picker([String])
}

struct ServerSelectionScreenViewState: BindableState {
    /// Whether the screen is configured to confirm a single account provider or pick one from a list of many.
    var mode: ServerSelectionScreenMode
    /// Whether the screen is configured for registration or existing account login
    var authenticationFlow: AuthenticationFlow
    /// The presentation anchor used for OAuth authentication.
    var window: UIWindow?
    
    /// View state that can be bound to from SwiftUI.
    var bindings: ServerSelectionScreenBindings
    
    /// Upon introspection, this is the UITextField backing the TextField for server input
    var textField: UITextField? {
        get { adapter.textField }
        set { adapter.textField = newValue }
    }
    
    /// Adapts the text field for custom functionality beyond what's available in SwiftUI
    let adapter = TextFieldAdapter()
    
    /// The header text for the screen
    var screenHeader: String {
        switch authenticationFlow {
        case .login:
            UntranslatedL10n.screenSelectServerTitleLogin
        case .register:
            UntranslatedL10n.screenSelectServerTitleRegister
        }
    }
    
    /// The message to be shown in the text field footer when no error has occurred.
    var regularFooterMessage: String {
        switch authenticationFlow {
        case .login:
            UntranslatedL10n.screenSelectServerTextfieldFooterLogin
        case .register:
            UntranslatedL10n.screenSelectServerTextfieldFooterRegister
        }
    }
    
    /// An error message to be shown in the text field footer.
    var footerErrorMessage: String?
    
    /// The message to show in the text field footer.
    var footerMessage: String {
        footerErrorMessage ?? regularFooterMessage
    }
    
    /// The text field is showing an error.
    var isShowingFooterError: Bool {
        footerErrorMessage != nil
    }
    
    /// Whether it is possible to continue when tapping the confirmation button.
    var hasValidationError: Bool {
        switch mode {
        case .userInput:
            bindings.homeserverAddress.isEmpty || isShowingFooterError
        case .picker(let options):
            !options.contains(bindings.homeserverAddress) || isShowingFooterError
        }
    }
}

struct ServerSelectionScreenBindings {
    /// The homeserver address input or chosen by the user.
    var homeserverAddress: String
    /// The selection range in `homeserverAddress`
    var homeserverSelection: TextSelection?
    
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<ServerSelectionScreenErrorType>?
}

enum ServerSelectionScreenViewAction {
    /// Updates the window used as the OAuth presentation anchor.
    case updateWindow(UIWindow)
    /// Updates the textfield from introspection
    case updateTextField(UITextField)
    /// The user would like to use the homeserver at the input address.
    case confirm
    /// Dismiss the view without using the entered address.
    case dismiss
    /// Clear any errors shown in the text field footer.
    case clearFooterError
}

enum ServerSelectionScreenErrorType: Hashable {
    /// An alert that informs the user about a bad well-known file.
    case invalidWellKnownAlert(String)
    /// An alert that allows the user to learn about sliding sync.
    case slidingSyncAlert
    /// An alert that informs the user that login isn't supported.
    case loginAlert
    /// An alert that informs the user that registration isn't supported.
    case registrationAlert
    /// An alert that informs the user that Element Pro should be used for a particular server.
    case elementProAlert
    /// An unknown error has occurred.
    case unknownError
}
