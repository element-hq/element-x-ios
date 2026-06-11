//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum OtpEntryScreenViewModelAction {
    case verify(code: String)
    case resend
    case changePhone
}

struct OtpEntryScreenViewState: BindableState {
    static let codeLength = 6

    var phoneNumber: String
    var isVerifying = false
    var errorMessage: String?
    var resendCountdownSeconds = 0

    var bindings: OtpEntryScreenViewStateBindings

    var canResend: Bool {
        !isVerifying && resendCountdownSeconds == 0
    }

    var canVerify: Bool {
        !isVerifying && Self.isValid(code: bindings.code)
    }

    static func isValid(code: String) -> Bool {
        code.count == codeLength && code.allSatisfy(\.isNumber)
    }
}

struct OtpEntryScreenViewStateBindings {
    var code = ""
}

enum OtpEntryScreenViewAction {
    case codeChanged
    case verifyTapped
    case resendTapped
    case changePhoneTapped
}
