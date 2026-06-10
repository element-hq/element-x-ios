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
            // Reject obviously weak PINs to mirror WhatsApp's basic strength check.
            if isWeak(pin: pin) {
                state.errorMessage = "Choose a less predictable PIN (avoid 000000, 123456, etc.)."
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

    private func isWeak(pin: String) -> Bool {
        // Reject all-same digits and trivial ascending/descending sequences.
        let weakPins: Set<String> = ["000000", "111111", "222222", "333333", "444444",
                                     "555555", "666666", "777777", "888888", "999999",
                                     "123456", "654321", "012345", "543210"]
        return weakPins.contains(pin)
    }
}
