//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum PinChallengeScreenViewModelAction {
    case verify(pin: String)
    case forgotPin
    case cancel
}

struct PinChallengeScreenViewState: BindableState {
    static let pinLength = 6

    let phoneNumber: String
    var isVerifying = false
    var errorMessage: String?
    var bindings: PinChallengeScreenViewStateBindings

    var canVerify: Bool {
        !isVerifying && Self.isValid(pin: bindings.pin)
    }

    static func isValid(pin: String) -> Bool {
        pin.count == pinLength && pin.allSatisfy(\.isNumber)
    }
}

struct PinChallengeScreenViewStateBindings {
    var pin = ""
}

enum PinChallengeScreenViewAction {
    case pinChanged
    case verifyTapped
    case forgotPinTapped
    case cancelTapped
}
