//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

enum ServerConfirmationScreenViewModelAction {
    /// The user would like to continue with the current homeserver.
    case confirm
    /// The user would like to change to a different homeserver.
    case changeServer
}

struct ServerConfirmationScreenViewState: BindableState {
    /// The homeserver address input by the user.
    var homeserverAddress: String
    /// The flow being attempted on the selected homeserver.
    let authenticationFlow: AuthenticationFlow
    /// Whether or not the homeserver supports registration.
    var homeserverSupportsRegistration = false
    /// The presentation anchor used for OIDC authentication.
    var window: UIWindow?
    
    /// The screen's title.
    var title: String {
        switch authenticationFlow {
        case .login:
            return L10n.screenServerConfirmationTitleLogin(homeserverAddress)
        case .register:
            return L10n.screenServerConfirmationTitleRegister(homeserverAddress)
        }
    }
    
    /// The message shown beneath the title.
    var message: String {
        switch authenticationFlow {
        case .login:
            if homeserverAddress == "matrix.org" {
                L10n.screenServerConfirmationMessageLoginMatrixDotOrg
            } else if homeserverAddress == "element.io" {
                L10n.screenServerConfirmationMessageLoginElementDotIo
            } else {
                ""
            }
        case .register:
            if canContinue {
                L10n.screenServerConfirmationMessageRegister
            } else {
                L10n.errorAccountCreationNotPossible
            }
        }
    }
    
    /// Whether or not it is valid to continue the flow.
    var canContinue: Bool {
        switch authenticationFlow {
        case .login: true
        case .register: homeserverSupportsRegistration
        }
    }
}

enum ServerConfirmationScreenViewAction {
    /// Updates the window used as the OIDC presentation anchor.
    case updateWindow(UIWindow)
    /// The user would like to continue with the current homeserver.
    case confirm
    /// The user would like to change to a different homeserver.
    case changeServer
}
