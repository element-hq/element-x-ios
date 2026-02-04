//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ReportProblemScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum ReportProblemScreenCoordinatorAction {
    case dismiss
}

final class ReportProblemScreenCoordinator: CoordinatorProtocol {
    private let viewModel: ReportProblemScreenViewModel
    private var cancellables = Set<AnyCancellable>()
    private let actionsSubject: PassthroughSubject<ReportProblemScreenCoordinatorAction, Never> = .init()

    var actions: AnyPublisher<ReportProblemScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }

    init(parameters: ReportProblemScreenCoordinatorParameters) {
        viewModel = ReportProblemScreenViewModel(userSession: parameters.userSession,
                                                 userIndicatorController: parameters.userIndicatorController)

        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .dismiss:
                    actionsSubject.send(.dismiss)
                }
            }
            .store(in: &cancellables)
    }

    func toPresentable() -> AnyView {
        AnyView(ReportProblemScreen(context: viewModel.context))
    }
}
