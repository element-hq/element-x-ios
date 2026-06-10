//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Foundation

enum TwoStepVerificationScreenViewModelAction {
    case close
}

/// Drives the screen between the overview state and the multi-step PIN flows.
///
/// Setup flow (no existing PIN):  ``enteringNew`` → ``confirmingNew`` → ``submitting``.
///
/// Change flow (existing PIN, OTP-protected):
/// ``enteringPhone`` → ``enteringCurrent`` (verified live with the backend) →
/// ``enteringOtp`` → ``enteringNew`` → ``confirmingNew`` → ``submitting``.
enum TwoStepVerificationScreenPhase: Equatable {
    case loading
    case overviewNoPin
    case overviewHasPin
    case enteringPhone
    case enteringCurrent
    case enteringOtp
    case enteringNew
    case confirmingNew
    case submitting
}

struct TwoStepVerificationScreenViewState: BindableState {
    static let pinLength = 6
    static let otpLength = 6

    var phase: TwoStepVerificationScreenPhase = .loading
    var phone = ""
    var selectedCountry: Country = .deviceDefault
    var currentPin = ""
    var challengeId: String?
    var otpCode = ""
    var stagedNewPin = ""
    var errorMessage: String?
    var bindings = TwoStepVerificationScreenViewStateBindings()

    var titleKey: String {
        switch phase {
        case .loading, .overviewNoPin, .overviewHasPin, .submitting:
            return L10n.screenTwoStepVerificationTitle
        case .enteringPhone:
            return L10n.screenTwoStepVerificationPhoneHeader
        case .enteringCurrent:
            return L10n.screenTwoStepVerificationCurrentHeader
        case .enteringOtp:
            return L10n.screenTwoStepVerificationOtpHeader
        case .enteringNew:
            return L10n.screenTwoStepVerificationNewHeader
        case .confirmingNew:
            return L10n.screenTwoStepVerificationConfirmHeader
        }
    }

    var footerKey: String {
        switch phase {
        case .enteringPhone:
            return L10n.screenTwoStepVerificationPhoneFooter
        case .enteringCurrent:
            return L10n.screenTwoStepVerificationCurrentFooter
        case .enteringOtp:
            return L10n.screenTwoStepVerificationOtpFooter
        case .enteringNew:
            return L10n.screenTwoStepVerificationNewFooter
        case .confirmingNew:
            return L10n.screenTwoStepVerificationConfirmFooter
        default:
            return ""
        }
    }

    var canContinue: Bool {
        switch phase {
        case .enteringPhone:
            return Self.isValid(phone: e164PhoneNumber) && !isWorking
        case .enteringCurrent, .enteringNew, .confirmingNew:
            return Self.isValid(pin: bindings.pin) && !isWorking
        case .enteringOtp:
            return Self.isValid(otp: bindings.pin) && !isWorking
        default:
            return false
        }
    }

    var isWorking: Bool { phase == .submitting }

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

struct TwoStepVerificationScreenViewStateBindings {
    /// Used for any of the 6-digit fields (current PIN, OTP, new PIN, confirmation).
    var pin = ""
    /// Country-formatted local phone digits typed during the change flow (dial code excluded).
    var localPhoneNumber = ""
    var isCountryPickerPresented = false
}

enum TwoStepVerificationScreenViewAction {
    case startSetup
    case startChange
    case pinChanged
    case phoneChanged
    case countrySelected(Country)
    case continueTapped
    case cancelEntry
}
