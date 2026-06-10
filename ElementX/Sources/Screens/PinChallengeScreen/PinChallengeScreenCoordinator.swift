//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct PinChallengeScreenCoordinatorParameters {
    let phoneNumber: String
}

enum PinChallengeScreenCoordinatorAction {
    case verify(pin: String)
    case forgotPin
    case cancel
}

final class PinChallengeScreenCoordinator: CoordinatorProtocol {
    private let parameters: PinChallengeScreenCoordinatorParameters
    private let viewModel: PinChallengeScreenViewModel

    private var cancellables = Set<AnyCancellable>()

    private let actionsSubject: PassthroughSubject<PinChallengeScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<PinChallengeScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(parameters: PinChallengeScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = PinChallengeScreenViewModel(phoneNumber: parameters.phoneNumber)
    }

    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .verify(let pin): actionsSubject.send(.verify(pin: pin))
            case .forgotPin: actionsSubject.send(.forgotPin)
            case .cancel: actionsSubject.send(.cancel)
            }
        }
        .store(in: &cancellables)
    }

    func setVerifying(_ isVerifying: Bool) { viewModel.setVerifying(isVerifying) }
    func displayError(_ message: String) { viewModel.displayError(message) }

    func toPresentable() -> AnyView {
        AnyView(PinChallengeScreen(context: viewModel.context))
    }
}
