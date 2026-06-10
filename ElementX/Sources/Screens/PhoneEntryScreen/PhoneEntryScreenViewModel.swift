//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias PhoneEntryScreenViewModelType = StateStoreViewModelV2<PhoneEntryScreenViewState, PhoneEntryScreenViewAction>

class PhoneEntryScreenViewModel: PhoneEntryScreenViewModelType, PhoneEntryScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<PhoneEntryScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<PhoneEntryScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(isLegacyAuthEnabled: Bool, initialPhoneNumber: String = "") {
        let (country, localDigits) = Self.parse(initialPhoneNumber: initialPhoneNumber)
        let formatted = country.formatNational(digits: localDigits)
        super.init(initialViewState: PhoneEntryScreenViewState(isLegacyAuthEnabled: isLegacyAuthEnabled,
                                                               selectedCountry: country,
                                                               bindings: .init(localPhoneNumber: formatted)))
    }

    // MARK: - Public

    func setSubmitting(_ isSubmitting: Bool) {
        state.isSubmitting = isSubmitting
        if isSubmitting { state.errorMessage = nil }
    }

    func displayError(_ message: String) {
        state.isSubmitting = false
        state.errorMessage = message
    }

    override func process(viewAction: PhoneEntryScreenViewAction) {
        switch viewAction {
        case .continueTapped:
            guard state.canContinue else { return }
            state.isSubmitting = true
            actionsSubject.send(.continue(phoneNumber: state.e164PhoneNumber))
        case .useLegacyAuthTapped:
            actionsSubject.send(.useLegacyAuth)
        case .countrySelected(let country):
            state.selectedCountry = country
            state.bindings.isCountryPickerPresented = false
            reformatNumber()
        case .phoneNumberChanged:
            autoDetectCountry()
            reformatNumber()
        }
    }
    
    /// Rewrites `bindings.localPhoneNumber` with the country-specific live-formatted version
    /// (e.g. `"51985550619"` → `"(51) 98555-0619"`). The text field's cursor jumps to the
    /// end on each reformat — acceptable trade-off for phone entry.
    private func reformatNumber() {
        let digits = state.bindings.localPhoneNumber.filter(\.isNumber)
        let formatted = state.selectedCountry.formatNational(digits: digits)
        if formatted != state.bindings.localPhoneNumber {
            state.bindings.localPhoneNumber = formatted
        }
    }

    /// Recomputes `selectedCountry` from the digits the user has typed, mirroring
    /// WhatsApp's behaviour: typing a Canadian area code (e.g. 343) flips the flag
    /// from US to CA; typing a Bahamian local number on US flips to BS; etc.
    private func autoDetectCountry() {
        if let detected = Country.detect(localDigits: state.localDigits,
                                         current: state.selectedCountry) {
            state.selectedCountry = detected
        }
    }

    // MARK: - Private

    /// Splits an optional pre-populated E.164 number into (country, localDigits).
    /// Falls back to the device's locale when the input is empty or unparseable.
    private static func parse(initialPhoneNumber: String) -> (Country, String) {
        let trimmed = initialPhoneNumber.trimmingCharacters(in: .whitespaces)
        guard trimmed.hasPrefix("+") else { return (Country.deviceDefault, "") }

        let digits = String(trimmed.dropFirst()).filter(\.isNumber)
        // Try longest-prefix match (some dial codes are 4 digits, e.g. +1876 for Jamaica).
        for length in stride(from: min(4, digits.count), through: 1, by: -1) {
            let prefix = String(digits.prefix(length))
            if let country = Country.all.first(where: { $0.dialCode == prefix }) {
                return (country, String(digits.dropFirst(length)))
            }
        }
        return (Country.deviceDefault, digits)
    }
}
