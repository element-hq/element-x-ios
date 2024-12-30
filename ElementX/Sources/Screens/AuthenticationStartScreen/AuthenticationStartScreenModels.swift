//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import SwiftUI

// MARK: - Coordinator

enum AuthenticationStartScreenCoordinatorAction {
    case loginManually
    case loginWithQR
    case register
    case reportProblem
    case verifyInviteCode(inviteCode: String)
}

enum AuthenticationStartScreenViewModelAction {
    case loginManually
    case loginWithQR
    case register
    case reportProblem
    case verifyInviteCode(inviteCode: String)
}

struct AuthenticationStartScreenViewState: BindableState {
    let VALID_INVITE_CODE_LENGTH = 6
    
    let isWebRegistrationEnabled: Bool
    let isQRCodeLoginEnabled: Bool
    
    var bindings = AuthenticationStartScreenBindings()
    
    var sendButtonDisabled: Bool {
        !isInviteCodeValid
    }
    
    var isInviteCodeValid: Bool {
        bindings.inviteCode.count == VALID_INVITE_CODE_LENGTH
    }
}

struct AuthenticationStartScreenBindings {
    var inviteCode = ""
}

enum AuthenticationStartScreenViewAction {
    case loginManually
    case loginWithQR
    case register
    case reportProblem
    case verifyInviteCode(inviteCode: String)
}
