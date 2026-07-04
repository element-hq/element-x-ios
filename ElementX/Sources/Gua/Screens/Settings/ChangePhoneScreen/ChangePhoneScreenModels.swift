//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

// GUA FORK: Change-phone-number flow. Mirrors the multi-step structure of the
// TwoStepVerificationScreen (PIN/OTP bubble fields, country-aware phone entry).
//
// Backend contract is PIN-step-up-first, gated on PIN status. On intro Continue we first
// `GET /security/pin/status`:
//   • no PIN → ``needsPinSetup`` interstitial (route to the 2SV PIN-setup flow; do not proceed).
//   • PIN present but `changePhoneCooldownRemainingSeconds > 0` → ``cooldown`` interstitial
//     (fresh-2FA cooldown; do not proceed).
//   • otherwise → ``pin`` as below.
// Flow:
//   ``intro`` → ``pin`` (6-digit account PIN; `POST /security/pin/reauth` → reauthToken, no SMS)
//   → ``newPhone`` (country-aware entry of the new number; `POST /otp/change-number/request` sends
//      the OTP to that number — the SMS only fires once a valid reauth token exists)
//   → ``otp`` (6-digit code from the new number; `POST /otp/change-number` consumes the reauth token
//      and atomically re-binds) → ``done``.

enum ChangePhoneScreenViewModelAction {
    case close
    /// The user has no PIN; route to the existing 2SV PIN-setup flow.
    case setUpPin
}

enum ChangePhoneScreenPhase: Equatable {
    case intro
    /// User has no PIN — interstitial telling them to set one up before they can change their number.
    case needsPinSetup
    /// PIN exists but was set/changed too recently (fresh-2FA cooldown) — change-phone is blocked for now.
    case cooldown
    case pin
    case newPhone
    case otp
    case submitting
    case done
}

struct ChangePhoneScreenViewState: BindableState {
    static let otpLength = 6
    static let pinLength = 6

    var phase: ChangePhoneScreenPhase = .intro
    var selectedCountry: Country = .deviceDefault
    /// The confirmed new number in E.164 form (e.g. "+15551234567").
    var newPhoneE164 = ""
    /// Short-lived PIN step-up token minted on the `.pin` step. Authorizes the OTP request and the
    /// final re-bind; the PIN itself is never replayed.
    var reauthToken = ""
    /// Remaining fresh-2FA cooldown in seconds; populated when entering the `.cooldown` phase.
    var cooldownRemainingSeconds = 0
    var errorMessage: String?
    var bindings = ChangePhoneScreenViewStateBindings()

    /// Human-readable cooldown message shown on the `.cooldown` interstitial.
    var cooldownMessage: String {
        guard cooldownRemainingSeconds > 0 else {
            return L10n.screenChangePhoneCooldownMessageGeneric
        }
        return L10n.screenChangePhoneCooldownMessage(IdentityServiceError.humanReadableDuration(seconds: cooldownRemainingSeconds))
    }

    var titleKey: String {
        switch phase {
        case .intro, .submitting, .done, .needsPinSetup, .cooldown:
            return L10n.screenChangePhoneTitle
        case .newPhone:
            return L10n.screenChangePhoneNewHeader
        case .pin:
            return L10n.screenChangePhonePinHeader
        case .otp:
            return L10n.screenChangePhoneOtpHeader
        }
    }

    var footerKey: String {
        switch phase {
        case .newPhone:
            return L10n.screenChangePhoneNewFooter
        case .pin:
            return L10n.screenChangePhonePinFooter
        case .otp:
            return L10n.screenChangePhoneOtpFooter
        default:
            return ""
        }
    }

    var canContinue: Bool {
        switch phase {
        case .newPhone:
            return Self.isValid(phone: e164PhoneNumber) && !isWorking
        case .pin:
            return Self.isValid(pin: bindings.code) && !isWorking
        case .otp:
            return Self.isValid(otp: bindings.code) && !isWorking
        default:
            return false
        }
    }

    var isWorking: Bool {
        phase == .submitting
    }

    /// Local subscriber digits typed by the user, stripped of any formatting characters.
    var localDigits: String {
        bindings.localPhoneNumber.filter(\.isNumber)
    }

    /// Full E.164 phone number to send to the backend (e.g. "+15551234567").
    var e164PhoneNumber: String {
        "+" + selectedCountry.dialCode + localDigits
    }

    static func isValid(pin: String) -> Bool {
        pin.count == pinLength && pin.allSatisfy(\.isNumber)
    }

    static func isValid(otp: String) -> Bool {
        otp.count == otpLength && otp.allSatisfy(\.isNumber)
    }

    static func isValid(phone: String) -> Bool {
        let trimmed = phone.trimmingCharacters(in: .whitespacesAndNewlines)
        guard trimmed.hasPrefix("+") else { return false }
        let digits = trimmed.dropFirst()
        return digits.count >= 8 && digits.count <= 15 && digits.allSatisfy(\.isNumber)
    }
}

struct ChangePhoneScreenViewStateBindings {
    /// Used for both 6-digit fields (account PIN, new-number OTP).
    var code = ""
    /// Country-formatted local phone digits for the new number (dial code excluded).
    var localPhoneNumber = ""
    var isCountryPickerPresented = false
}

enum ChangePhoneScreenViewAction {
    case start
    case codeChanged
    case phoneChanged
    case countrySelected(Country)
    case continueTapped
    case cancel
    case done
    /// Tapped the "Set up PIN" button on the `.needsPinSetup` interstitial.
    case setUpPin
}
