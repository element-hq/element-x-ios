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

import SwiftUI

struct SoftLogoutScreenCredentials {
    let userId: String
    let homeserverName: String
    let userDisplayName: String
    let deviceId: String?
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
    /// An unknown error occurred.
    case unknown
}
