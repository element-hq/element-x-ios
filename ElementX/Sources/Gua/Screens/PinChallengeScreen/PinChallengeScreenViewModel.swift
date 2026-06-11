//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias PinChallengeScreenViewModelType = StateStoreViewModelV2<PinChallengeScreenViewState, PinChallengeScreenViewAction>

class PinChallengeScreenViewModel: PinChallengeScreenViewModelType, PinChallengeScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<PinChallengeScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<PinChallengeScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(phoneNumber: String) {
        super.init(initialViewState: PinChallengeScreenViewState(phoneNumber: phoneNumber,
                                                                 bindings: .init()))
    }

    func setVerifying(_ isVerifying: Bool) {
        state.isVerifying = isVerifying
        if isVerifying { state.errorMessage = nil }
    }

    func displayError(_ message: String) {
        state.isVerifying = false
        state.errorMessage = message
        state.bindings.pin = ""
    }

    override func process(viewAction: PinChallengeScreenViewAction) {
        switch viewAction {
        case .pinChanged:
            let cleaned = String(state.bindings.pin.filter(\.isNumber).prefix(PinChallengeScreenViewState.pinLength))
            if cleaned != state.bindings.pin {
                state.bindings.pin = cleaned
            }
            // Auto-submit once the full 6 digits are entered, matching WhatsApp's flow.
            if PinChallengeScreenViewState.isValid(pin: cleaned), !state.isVerifying {
                state.isVerifying = true
                actionsSubject.send(.verify(pin: cleaned))
            }
        case .verifyTapped:
            guard state.canVerify else { return }
            state.isVerifying = true
            actionsSubject.send(.verify(pin: state.bindings.pin))
        case .forgotPinTapped:
            actionsSubject.send(.forgotPin)
        case .cancelTapped:
            actionsSubject.send(.cancel)
        }
    }
}
