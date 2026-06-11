//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias PinSetupScreenViewModelType = StateStoreViewModelV2<PinSetupScreenViewState, PinSetupScreenViewAction>

class PinSetupScreenViewModel: PinSetupScreenViewModelType, PinSetupScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<PinSetupScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<PinSetupScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init() {
        super.init(initialViewState: PinSetupScreenViewState(bindings: .init()))
    }

    func setSubmitting(_ isSubmitting: Bool) {
        state.isSubmitting = isSubmitting
        if isSubmitting { state.errorMessage = nil }
    }

    func displayError(_ message: String) {
        state.isSubmitting = false
        state.errorMessage = message
        state.bindings.pin = ""
    }

    override func process(viewAction: PinSetupScreenViewAction) {
        // Guard against duplicate submissions — auto-submit on the last digit can race with
        // the Continue button, and the signup token is single-use on the backend.
        guard !state.isSubmitting else { return }
        switch viewAction {
        case .pinChanged:
            let cleaned = String(state.bindings.pin.filter(\.isNumber).prefix(PinSetupScreenViewState.pinLength))
            if cleaned != state.bindings.pin {
                state.bindings.pin = cleaned
            }
            if state.errorMessage != nil { state.errorMessage = nil }
            if PinSetupScreenViewState.isValid(pin: cleaned) {
                advanceFromAutoFill(pin: cleaned)
            }
        case .continueTapped:
            guard state.canContinue else { return }
            advanceFromAutoFill(pin: state.bindings.pin)
        case .skipTapped:
            state.isSubmitting = true
            actionsSubject.send(.skip)
        }
    }

    private func advanceFromAutoFill(pin: String) {
        switch state.step {
        case .create:
            // Reject weak PINs to mirror identity-service's PinPolicy. The server
            // re-validates and remains authoritative; this is for instant feedback.
            if isWeak(pin: pin) {
                state.errorMessage = "That PIN is too easy to guess. Avoid repeated, sequential, or common PINs."
                state.bindings.pin = ""
                return
            }
            state.initialPin = pin
            state.bindings.pin = ""
            state.step = .confirm
        case .confirm:
            guard pin == state.initialPin else {
                state.errorMessage = "PINs don't match. Try again."
                state.bindings.pin = ""
                state.initialPin = ""
                state.step = .create
                return
            }
            state.isSubmitting = true
            actionsSubject.send(.complete(pin: pin))
        }
    }

    /// Mirrors identity-service `PinPolicy`: rejects all-repeated digits, strictly
    /// sequential runs (ascending/descending by 1), and a curated common-PIN
    /// denylist. Keep in sync with PinPolicy.java / pinPolicy.ts.
    private func isWeak(pin: String) -> Bool {
        guard pin.count == PinSetupScreenViewState.pinLength, pin.allSatisfy(\.isNumber) else {
            return false
        }
        if isRepeated(pin) || isSequential(pin) || Self.commonPins.contains(pin) {
            return true
        }
        return false
    }

    private func isRepeated(_ pin: String) -> Bool {
        Set(pin).count == 1
    }

    private func isSequential(_ pin: String) -> Bool {
        let digits = pin.compactMap(\.wholeNumberValue)
        guard digits.count == pin.count else { return false }
        var ascending = true
        var descending = true
        for index in 1..<digits.count {
            let delta = digits[index] - digits[index - 1]
            if delta != 1 { ascending = false }
            if delta != -1 { descending = false }
        }
        return ascending || descending
    }

    private static let commonPins: Set<String> = [
        "123123", "121212", "123321", "112233", "123654", "159753",
        "147258", "159357", "753951", "357159", "142536", "789456",
        "456789", "696969", "777777", "131313", "101010", "102030",
        "201020", "232323", "456123", "987654", "654321", "212121",
        "120120", "110110", "100100", "808080", "520520", "999999",
        "888888"
    ]
}
