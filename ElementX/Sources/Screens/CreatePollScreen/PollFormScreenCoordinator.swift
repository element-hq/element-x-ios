//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct PollFormScreenCoordinatorParameters {
    let mode: PollFormMode
    /// The max number of allowed options, if no value provided the default value of the view model will be used.
    var maxNumberOfOptions: Int?
    let timelineController: TimelineControllerProtocol
    let analytics: AnalyticsService
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum PollFormScreenCoordinatorAction {
    case close
}

final class PollFormScreenCoordinator: CoordinatorProtocol {
    private var viewModel: PollFormScreenViewModelProtocol
    private let actionsSubject: PassthroughSubject<PollFormScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<PollFormScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: PollFormScreenCoordinatorParameters) {
        viewModel = PollFormScreenViewModel(mode: parameters.mode,
                                            maxNumberOfOptions: parameters.maxNumberOfOptions,
                                            timelineController: parameters.timelineController,
                                            analytics: parameters.analytics,
                                            userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .close:
                self.actionsSubject.send(.close)
            }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(PollFormScreen(context: viewModel.context))
    }
}
