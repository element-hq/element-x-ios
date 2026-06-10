//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum EncryptionResetPasswordScreenViewModelAction {
    case passwordEntered
}

/// Reauth phases for the OTP-based UIA path used by the Gua app. When the identity-service
/// client is unavailable (e.g. dev builds without backend) we fall back to the legacy password
/// entry path so existing behaviour is preserved.
enum EncryptionResetReauthPhase: Equatable {
    case idle
    case sendingCode
    case awaitingCode
    case verifyingCode
    case resolving
    case error(String)
}

struct EncryptionResetPasswordScreenViewState: BindableState {
    let identityServiceAvailable: Bool
    var reauthPhase: EncryptionResetReauthPhase = .idle
    var bindings: EncryptionResetPasswordScreenViewStateBindings
}

struct EncryptionResetPasswordScreenViewStateBindings {
    var password: String
    var otpCode = ""
    var alertInfo: AlertInfo<UUID>?
}

enum EncryptionResetPasswordScreenViewAction {
    case submit
    case sendReauthCode
    case verifyReauthCode
}
