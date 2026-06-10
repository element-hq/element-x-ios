//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

enum PinSetupScreenCoordinatorAction {
    case complete(pin: String)
    case skip
}

final class PinSetupScreenCoordinator: CoordinatorProtocol {
    private let viewModel: PinSetupScreenViewModel
    private var cancellables = Set<AnyCancellable>()

    private let actionsSubject: PassthroughSubject<PinSetupScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<PinSetupScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init() {
        viewModel = PinSetupScreenViewModel()
    }

    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete(let pin): actionsSubject.send(.complete(pin: pin))
            case .skip: actionsSubject.send(.skip)
            }
        }
        .store(in: &cancellables)
    }

    func displayError(_ message: String) { viewModel.displayError(message) }
    func setSubmitting(_ isSubmitting: Bool) { viewModel.setSubmitting(isSubmitting) }

    func toPresentable() -> AnyView {
        AnyView(PinSetupScreen(context: viewModel.context))
    }
}
