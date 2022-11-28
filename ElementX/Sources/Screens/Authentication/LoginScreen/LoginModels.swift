//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Foundation

enum LoginViewModelAction: CustomStringConvertible {
    /// The user would like to select another server.
    case selectServer
    /// Parse the username and update the homeserver if included.
    case parseUsername(String)
    /// The user would like to reset their password.
    case forgotPassword
    /// Login using the supplied credentials.
    case login(username: String, password: String)
    /// Continue using OIDC.
    case continueWithOIDC
    
    /// A string representation of the action, ignoring any associated values that could leak PII.
    var description: String {
        switch self {
        case .selectServer:
            return "selectServer"
        case .parseUsername:
            return "parseUsername"
        case .forgotPassword:
            return "forgotPassword"
        case .login:
            return "login"
        case .continueWithOIDC:
            return "continueWithOIDC"
        }
    }
}

struct LoginViewState: BindableState {
    /// Data about the selected homeserver.
    var homeserver: LoginHomeserver
    /// Whether a new homeserver is currently being loaded.
    var isLoading = false
    /// View state that can be bound to from SwiftUI.
    var bindings: LoginBindings
    
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

struct LoginBindings {
    /// The username input by the user.
    var username = ""
    /// The password input by the user.
    var password = ""
    /// Information describing the currently displayed alert.
    var alertInfo: AlertInfo<LoginErrorType>?
}

enum LoginViewAction {
    /// The user would like to select another server.
    case selectServer
    /// Parse the username to detect if a homeserver is included.
    case parseUsername
    /// The user would like to reset their password.
    case forgotPassword
    /// Continue using the input username and password.
    case next
    /// Continue using OIDC.
    case continueWithOIDC
}

enum LoginErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert(String)
    /// Looking up the homeserver from the username failed.
    case invalidHomeserver
    /// The response from the homeserver was unexpected.
    case unknown
}
