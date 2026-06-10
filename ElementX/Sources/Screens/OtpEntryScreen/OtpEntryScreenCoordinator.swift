//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

// periphery:ignore:all - this is just a otpEntry remove this comment once generating the final file

import Combine
import SwiftUI

struct OtpEntryScreenCoordinatorParameters {
    let phoneNumber: String
    let initialResendCountdown: Int

    init(phoneNumber: String, initialResendCountdown: Int = 30) {
        self.phoneNumber = phoneNumber
        self.initialResendCountdown = initialResendCountdown
    }
}

enum OtpEntryScreenCoordinatorAction {
    case verify(code: String)
    case resend
    case changePhone
}

final class OtpEntryScreenCoordinator: CoordinatorProtocol {
    private let parameters: OtpEntryScreenCoordinatorParameters
    private let viewModel: OtpEntryScreenViewModel

    private var cancellables = Set<AnyCancellable>()

    private let actionsSubject: PassthroughSubject<OtpEntryScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<OtpEntryScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(parameters: OtpEntryScreenCoordinatorParameters) {
        self.parameters = parameters

        viewModel = OtpEntryScreenViewModel(phoneNumber: parameters.phoneNumber,
                                            initialResendCountdown: parameters.initialResendCountdown)
    }

    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .verify(let code):
                actionsSubject.send(.verify(code: code))
            case .resend:
                actionsSubject.send(.resend)
            case .changePhone:
                actionsSubject.send(.changePhone)
            }
        }
        .store(in: &cancellables)
    }

    func setVerifying(_ isVerifying: Bool) {
        viewModel.setVerifying(isVerifying)
    }

    func displayError(_ message: String) {
        viewModel.displayError(message)
    }

    func resetForResend(initialResendCountdown: Int = 30) {
        viewModel.resetForResend(initialResendCountdown: initialResendCountdown)
    }

    func toPresentable() -> AnyView {
        AnyView(OtpEntryScreen(context: viewModel.context))
    }
}
