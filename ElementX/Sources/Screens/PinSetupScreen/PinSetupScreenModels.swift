//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum PinSetupScreenViewModelAction {
    /// User confirmed a matching 6-digit PIN.
    case complete(pin: String)
    /// User chose to skip PIN setup for now.
    case skip
}

enum PinSetupStep {
    case create
    case confirm
}

struct PinSetupScreenViewState: BindableState {
    static let pinLength = 6

    var step: PinSetupStep = .create
    /// Captured during the `.create` step; used to compare against the confirmation entry.
    var initialPin = ""
    var isSubmitting = false
    var errorMessage: String?
    var bindings: PinSetupScreenViewStateBindings

    var canContinue: Bool {
        !isSubmitting && Self.isValid(pin: bindings.pin)
    }

    var titleKey: String {
        switch step {
        case .create: L10n.screenPinSetupCreateHeader
        case .confirm: L10n.screenPinSetupConfirmHeader
        }
    }

    var footerKey: String {
        switch step {
        case .create: L10n.screenPinSetupCreateFooter
        case .confirm: L10n.screenPinSetupConfirmFooter
        }
    }

    static func isValid(pin: String) -> Bool {
        pin.count == pinLength && pin.allSatisfy(\.isNumber)
    }
}

struct PinSetupScreenViewStateBindings {
    var pin = ""
}

enum PinSetupScreenViewAction {
    case pinChanged
    case continueTapped
    case skipTapped
}
