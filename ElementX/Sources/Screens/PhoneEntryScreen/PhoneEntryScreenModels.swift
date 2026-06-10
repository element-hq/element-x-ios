//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum PhoneEntryScreenViewModelAction {
    case `continue`(phoneNumber: String)
    case useLegacyAuth
}

struct PhoneEntryScreenViewState: BindableState {
    var isLegacyAuthEnabled: Bool
    var selectedCountry: Country
    var isSubmitting = false
    var errorMessage: String?

    var bindings: PhoneEntryScreenViewStateBindings

    /// User-entered digits, stripped of any non-numeric characters.
    var localDigits: String {
        bindings.localPhoneNumber.filter(\.isNumber)
    }

    /// Full E.164 phone number to send to the backend (e.g. "+15551234567").
    var e164PhoneNumber: String {
        "+" + selectedCountry.dialCode + localDigits
    }

    var canContinue: Bool {
        !isSubmitting && Self.isValid(localDigits: localDigits, dialCode: selectedCountry.dialCode)
    }

    /// E.164 numbers are 1–15 digits including the country code. Subscriber number
    /// minimum is generally 4 digits (e.g. small island states), so we require at
    /// least that and cap the total length.
    static func isValid(localDigits: String, dialCode: String) -> Bool {
        let totalDigits = dialCode.count + localDigits.count
        return localDigits.count >= 4 && totalDigits <= 15
    }
}

struct PhoneEntryScreenViewStateBindings {
    /// Digits typed by the user, excluding the dial code.
    var localPhoneNumber = ""
    var isCountryPickerPresented = false
}

enum PhoneEntryScreenViewAction {
    case continueTapped
    case useLegacyAuthTapped
    case countrySelected(Country)
    case phoneNumberChanged
}
