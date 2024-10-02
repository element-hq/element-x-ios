//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

struct SoftLogoutScreenCredentials {
    let userID: String
    let homeserverName: String
    let userDisplayName: String
    let deviceID: String?
}

enum SoftLogoutScreenViewModelAction: CustomStringConvertible {
    /// Login with password
    case login(String)
    /// Forgot password
    case forgotPassword
    /// Clear all user data
    case clearAllData
    /// Continue using OIDC.
    case continueWithOIDC
    
    /// A string representation of the result, ignoring any associated values that could leak PII.
    var description: String {
        switch self {
        case .login:
            return "login"
        case .forgotPassword:
            return "forgotPassword"
        case .clearAllData:
            return "clearAllData"
        case .continueWithOIDC:
            return "continueWithOIDC"
        }
    }
}

struct SoftLogoutScreenViewState: BindableState {
    /// Soft logout credentials
    var credentials: SoftLogoutScreenCredentials

    /// Data about the selected homeserver.
    var homeserver: LoginHomeserver

    /// Flag indicating soft logged out user needs backup for some keys
    var keyBackupNeeded: Bool

    /// View state that can be bound to from SwiftUI.
    var bindings: SoftLogoutScreenBindings

    /// The types of login supported by the homeserver.
    var loginMode: LoginMode { homeserver.loginMode }
    
    /// The presentation anchor used for OIDC authentication.
    var window: UIWindow?

    /// Whether to show recover encryption keys message
    var showRecoverEncryptionKeysMessage: Bool {
        keyBackupNeeded
    }

    /// `true` when valid credentials have been entered and a homeserver has been loaded.
    var canSubmit: Bool {
        !bindings.password.isEmpty
    }
}

struct SoftLogoutScreenBindings {
    /// The password input by the user.
    var password: String
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<SoftLogoutScreenErrorType>?
}

enum SoftLogoutScreenViewAction {
    /// Updates the window used as the OIDC presentation anchor.
    case updateWindow(UIWindow?)
    /// Login.
    case login
    /// Forgot password
    case forgotPassword
    /// Clear all user data.
    case clearAllData
    /// Continue using OIDC.
    case continueWithOIDC
}

enum SoftLogoutScreenErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert(String)
    /// An alert that informs the user that login failed due to a refresh token being returned.
    case refreshTokenAlert
    /// An unknown error occurred.
    case unknown
}
