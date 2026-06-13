//
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct TwoStepVerificationScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
    let identityServiceClient: IdentityServiceClientProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum TwoStepVerificationScreenCoordinatorAction {
    case close
}

final class TwoStepVerificationScreenCoordinator: CoordinatorProtocol {
    private let parameters: TwoStepVerificationScreenCoordinatorParameters
    private let viewModel: TwoStepVerificationScreenViewModelProtocol

    private var cancellables = Set<AnyCancellable>()

    private let actionsSubject: PassthroughSubject<TwoStepVerificationScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<TwoStepVerificationScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(parameters: TwoStepVerificationScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = TwoStepVerificationScreenViewModel(clientProxy: parameters.clientProxy,
                                                       identityServiceClient: parameters.identityServiceClient,
                                                       userIndicatorController: parameters.userIndicatorController)
    }

    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            guard let self else { return }
            switch action {
            case .close:
                actionsSubject.send(.close)
            }
        }
        .store(in: &cancellables)
    }

    func toPresentable() -> AnyView {
        AnyView(TwoStepVerificationScreen(context: viewModel.context))
    }
}
