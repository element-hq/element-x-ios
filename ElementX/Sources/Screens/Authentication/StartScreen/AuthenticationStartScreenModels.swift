//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum AuthenticationStartScreenViewModelAction: Equatable {
    case loginWithQR
    case login
    case register
    
    case loginDirectlyWithOAuth(data: OAuthAuthorizationDataProxy, window: UIWindow)
    case loginDirectlyWithPassword(loginHint: String?)
    
    case reportProblem
    case developerOptions
}

struct AuthenticationStartScreenViewState: BindableState {
    enum Mode: Equatable {
        case welcome
        case addAccount
        case classicAppWelcomeBack(ClassicAppAccount)
        case classicAppOtherOptions(ClassicAppAccount)
    }
    
    var mode: Mode
    
    let serverNameOrBaseURL: String?
    let showCreateAccountButton: Bool
    let showQRCodeLoginButton: Bool
    let hideBrandChrome: Bool
    
    /// The presentation anchor used for OAuth authentication.
    var window: UIWindow?
    
    var bindings = AuthenticationStartScreenViewStateBindings()
    
    var navigationTitle: String {
        switch mode {
        case .welcome, .classicAppWelcomeBack, .classicAppOtherOptions:
            L10n.screenOnboardingWelcomeBack
        case .addAccount:
            L10n.commonAddAnotherAccount
        }
    }
    
    var navigationBarHidden: Bool {
        switch mode {
        case .welcome:
            true
        case .addAccount, .classicAppWelcomeBack, .classicAppOtherOptions:
            false
        }
    }
    
    var loginButtonTitle: String {
        if let serverNameOrBaseURL {
            L10n.screenOnboardingSignInTo(serverNameOrBaseURL)
        } else if showQRCodeLoginButton {
            L10n.screenOnboardingSignInManually
        } else {
            L10n.actionContinue
        }
    }
}

struct AuthenticationStartScreenViewStateBindings {
    var alertInfo: AlertInfo<AuthenticationStartScreenAlertType>?
    var showClassicAppBackupInstructions = false
}

enum AuthenticationStartScreenAlertType {
    case genericError
}

enum AuthenticationStartScreenViewAction {
    /// Updates the window used as the OAuth presentation anchor.
    case updateWindow(UIWindow)
    case developerOptions
    case reportProblem
    
    case loginWithQR
    case login
    case register
    
    case continueWithClassic(ClassicAppAccount)
    case otherOptions(ClassicAppAccount)
    case closeOtherOptions(ClassicAppAccount)
    case openClassicApp
}
