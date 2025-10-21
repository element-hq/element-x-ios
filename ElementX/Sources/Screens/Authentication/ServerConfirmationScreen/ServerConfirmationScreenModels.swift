//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum ServerConfirmationScreenViewModelAction {
    /// Continue the flow using the provided OIDC parameters.
    case continueWithOIDC(data: OIDCAuthorizationDataProxy, window: UIWindow)
    /// Continue the flow using password authentication.
    case continueWithPassword
    /// The user would like to change to a different homeserver.
    case changeServer
}

enum ServerConfirmationScreenMode: Equatable {
    /// The user is confirming the displayed account provider (or can enter their own).
    case confirmation(String)
    /// The user is only allowed to pick from a list of account providers.
    case picker([String])
}

struct ServerConfirmationScreenViewState: BindableState {
    /// Whether the screen is configured to confirm a single account provider or pick one from a list of many.
    var mode: ServerConfirmationScreenMode
    /// The flow being attempted on the selected homeserver.
    let authenticationFlow: AuthenticationFlow
    /// The presentation anchor used for OIDC authentication.
    var window: UIWindow?
    
    var bindings = ServerConfirmationScreenBindings()
    
    /// The screen's title.
    var title: String {
        switch mode {
        case .confirmation(let accountProvider):
            switch authenticationFlow {
            case .login:
                L10n.screenServerConfirmationTitleLogin(accountProvider)
            case .register:
                L10n.screenServerConfirmationTitleRegister(accountProvider)
            }
        case .picker:
            L10n.screenServerConfirmationTitlePickerMode
        }
    }
    
    /// The message shown beneath the title.
    var message: String? {
        guard case let .confirmation(homeserverAddress) = mode else { return nil }

        return switch authenticationFlow {
        case .login:
            if homeserverAddress == "matrix.org" {
                L10n.screenServerConfirmationMessageLoginMatrixDotOrg
            } else if homeserverAddress == "element.io" {
                L10n.screenServerConfirmationMessageLoginElementDotIo
            } else {
                ""
            }
        case .register:
            L10n.screenServerConfirmationMessageRegister
        }
    }
}

struct ServerConfirmationScreenBindings {
    /// The chosen server when in `.picker` mode, otherwise `nil`.
    var pickerSelection: String?
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<ServerConfirmationScreenAlert>?
}

enum ServerConfirmationScreenViewAction {
    /// Updates the window used as the OIDC presentation anchor.
    case updateWindow(UIWindow)
    /// The user would like to continue with the current homeserver.
    case confirm
    /// The user would like to change to a different homeserver.
    case changeServer
}

enum ServerConfirmationScreenAlert: Hashable {
    /// An alert that informs the user that a server could not be found.
    case homeserverNotFound
    /// An alert that informs the user about a bad well-known file.
    case invalidWellKnown(String)
    /// An alert that allows the user to learn about sliding sync.
    case slidingSync
    /// An alert that informs the user that login isn't supported.
    case login
    /// An alert that informs the user that registration isn't supported.
    case registration
    /// An alert that informs the user that Element Pro should be used for a particular server.
    case elementProRequired(serverName: String)
    /// An unknown error has occurred.
    case unknownError
}
