//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

enum CreateAccountScreenCoordinatorAction {
    case accountCreated
    case openLoginScreen
}

enum CreateAccountScreenViewModelAction {
    case openLoginScreen
}

struct CreateAccountScreenViewState: BindableState {
    let inviteCode: String
    
    var bindings = CreateAccountScreenBindings()
    
    var hasValidInput: Bool {
        !bindings.emailAddress.isEmpty &&
        !bindings.password.isEmpty &&
        !bindings.confirmPassword.isEmpty
    }
    
    /// `true` when valid credentials have been entered and a homeserver has been loaded.
    var canSubmit: Bool {
        hasValidInput
    }
}

struct CreateAccountScreenBindings {
    var emailAddress: String = ""
    var password: String = ""
    var confirmPassword: String = ""
    
    var alertInfo: AlertInfo<CreateAccountScreenErrorType>?
}

enum CreateAccountScreenErrorType: Hashable {
    /// A specific error message shown in an alert.
    case alert(String)
    /// An alert that informs the user to check their username/password.
    case credentialsAlert
    /// The response from the homeserver was unexpected.
    case unknown
}

enum CreateAccountScreenViewAction {
    case openLoginScreen
    case createAccount
}
