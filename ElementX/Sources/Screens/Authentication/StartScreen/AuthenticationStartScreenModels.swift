//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

// MARK: - Coordinator

enum AuthenticationStartScreenCoordinatorAction {
    case loginWithQR
    case login
    case register
    case reportProblem
    
    case loginDirectlyWithOIDC(data: OIDCAuthorizationDataProxy, window: UIWindow)
    case loginDirectlyWithPassword(loginHint: String?)
}

enum AuthenticationStartScreenViewModelAction: Equatable {
    case loginWithQR
    case login
    case register
    case reportProblem
    
    case loginDirectlyWithOIDC(data: OIDCAuthorizationDataProxy, window: UIWindow)
    case loginDirectlyWithPassword(loginHint: String?)
}

struct AuthenticationStartScreenViewState: BindableState {
    /// The presentation anchor used for OIDC authentication.
    var window: UIWindow?
    
    let serverName: String?
    let showCreateAccountButton: Bool
    let showQRCodeLoginButton: Bool
    
    let hideBrandChrome: Bool
    
    var bindings = AuthenticationStartScreenViewStateBindings()
    
    var loginButtonTitle: String {
        if let serverName {
            L10n.screenOnboardingSignInTo(serverName)
        } else if showQRCodeLoginButton {
            L10n.screenOnboardingSignInManually
        } else {
            L10n.actionContinue
        }
    }
}

struct AuthenticationStartScreenViewStateBindings {
    var alertInfo: AlertInfo<AuthenticationStartScreenAlertType>?
}

enum AuthenticationStartScreenAlertType {
    case genericError
}

enum AuthenticationStartScreenViewAction {
    /// Updates the window used as the OIDC presentation anchor.
    case updateWindow(UIWindow)
    
    case loginWithQR
    case login
    case register
    case reportProblem
}
