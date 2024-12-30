//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

// MARK: - Coordinator

enum CreateAccountScreenCoordinatorAction {
    case accountCreated(userSession: UserSessionProtocol)
    case openLoginScreen
}

enum CreateAccountScreenViewModelAction {
    case accountCreated(userSession: UserSessionProtocol)
    case openLoginScreen
}

struct CreateAccountScreenViewState: BindableState {
    let inviteCode: String
    
    var bindings = CreateAccountScreenBindings()
    
    var isEmailValid: Bool {
        !bindings.emailAddress.isEmpty && ValidationUtil.shared.isValidEmail(bindings.emailAddress)
    }
    
    var isValidPassword: Bool {
        !bindings.password.isEmpty && ValidationUtil.shared.isValidPassword(bindings.password)
    }
    
    var isValidConfirmPassword: Bool {
        !bindings.confirmPassword.isEmpty && (bindings.password == bindings.confirmPassword)
    }
    
    var hasValidInput: Bool {
        isEmailValid && isValidPassword && isValidConfirmPassword
    }
    
    var canSubmit: Bool {
        hasValidInput
    }
}

struct CreateAccountScreenBindings {
    var emailAddress = ""
    var password = ""
    var confirmPassword = ""
    
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
    case openWalletConnectModal
}
