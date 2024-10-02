//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum LoginScreenViewModelAction: CustomStringConvertible {
    /// Parse the username and update the homeserver if included.
    case parseUsername(String)
    /// The user would like to reset their password.
    case forgotPassword
    /// Login using the supplied credentials.
    case login(username: String, password: String)
    
    /// A string representation of the action, ignoring any associated values that could leak PII.
    var description: String {
        switch self {
        case .parseUsername:
            return "parseUsername"
        case .forgotPassword:
            return "forgotPassword"
        case .login:
            return "login"
        }
    }
}

struct LoginScreenViewState: BindableState {
    /// Data about the selected homeserver.
    var homeserver: LoginHomeserver
    /// Whether a new homeserver is currently being loaded.
    var isLoading = false
    /// View state that can be bound to from SwiftUI.
    var bindings: LoginScreenBindings
    
    /// The types of login supported by the homeserver.
    var loginMode: LoginMode { homeserver.loginMode }
    
    /// `true` if the username and password are ready to be submitted.
    var hasValidCredentials: Bool {
        !bindings.username.isEmpty && !bindings.password.isEmpty
    }
    
    /// `true` when valid credentials have been entered and a homeserver has been loaded.
    var canSubmit: Bool {
        hasValidCredentials && !isLoading
    }
}

struct LoginScreenBindings {
    /// The username input by the user.
    var username = ""
    /// The password input by the user.
    var password = ""
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<LoginScreenErrorType>?
}

enum LoginScreenViewAction {
    /// Parse the username to detect if a homeserver is included.
    case parseUsername
    /// The user would like to reset their password.
    case forgotPassword
    /// Continue using the input username and password.
    case next
}

enum LoginScreenErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert(String)
    /// Looking up the homeserver from the username failed.
    case invalidHomeserver
    /// An alert that informs the user about a bad well-known file.
    case invalidWellKnownAlert(String)
    /// An alert that allows the user to learn about sliding sync.
    case slidingSyncAlert
    /// An alert that informs the user that login failed due to a refresh token being returned.
    case refreshTokenAlert
    /// The response from the homeserver was unexpected.
    case unknown
}
