//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias OtpEntryScreenViewModelType = StateStoreViewModelV2<OtpEntryScreenViewState, OtpEntryScreenViewAction>

class OtpEntryScreenViewModel: OtpEntryScreenViewModelType, OtpEntryScreenViewModelProtocol {
    private let actionsSubject: PassthroughSubject<OtpEntryScreenViewModelAction, Never> = .init()
    var actionsPublisher: AnyPublisher<OtpEntryScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    private var countdownTask: Task<Void, Never>?

    init(phoneNumber: String, initialResendCountdown: Int = 30) {
        super.init(initialViewState: OtpEntryScreenViewState(phoneNumber: phoneNumber,
                                                             resendCountdownSeconds: initialResendCountdown,
                                                             bindings: .init()))
        startResendCountdown()
    }

    // MARK: - Public

    func setVerifying(_ isVerifying: Bool) {
        state.isVerifying = isVerifying
        if isVerifying { state.errorMessage = nil }
    }

    func displayError(_ message: String) {
        state.isVerifying = false
        state.errorMessage = message
    }

    func resetForResend(initialResendCountdown: Int = 30) {
        state.bindings.code = ""
        state.errorMessage = nil
        state.isVerifying = false
        state.resendCountdownSeconds = initialResendCountdown
        startResendCountdown()
    }

    override func process(viewAction: OtpEntryScreenViewAction) {
        switch viewAction {
        case .codeChanged:
            // Drop any non-digit characters and clamp to the expected length.
            let cleaned = String(state.bindings.code.filter(\.isNumber).prefix(OtpEntryScreenViewState.codeLength))
            if cleaned != state.bindings.code {
                state.bindings.code = cleaned
            }
            if OtpEntryScreenViewState.isValid(code: cleaned), !state.isVerifying {
                state.isVerifying = true
                actionsSubject.send(.verify(code: cleaned))
            }
        case .verifyTapped:
            guard state.canVerify else { return }
            state.isVerifying = true
            actionsSubject.send(.verify(code: state.bindings.code))
        case .resendTapped:
            guard state.canResend else { return }
            actionsSubject.send(.resend)
        case .changePhoneTapped:
            actionsSubject.send(.changePhone)
        }
    }

    // MARK: - Private

    private func startResendCountdown() {
        countdownTask?.cancel()
        guard state.resendCountdownSeconds > 0 else { return }

        countdownTask = Task { [weak self] in
            while let self, !Task.isCancelled, await self.state.resendCountdownSeconds > 0 {
                try? await Task.sleep(for: .seconds(1))
                guard !Task.isCancelled else { return }
                await MainActor.run { self.state.resendCountdownSeconds = max(0, self.state.resendCountdownSeconds - 1) }
            }
        }
    }

    deinit {
        countdownTask?.cancel()
    }
}
