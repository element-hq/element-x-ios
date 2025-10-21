//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct StaticLocationScreenCoordinatorParameters {
    let interactionMode: StaticLocationInteractionMode
    let mapURLBuilder: MapTilerURLBuilderProtocol
    let timelineController: TimelineControllerProtocol
    let appMediator: AppMediatorProtocol
    let analytics: AnalyticsService
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum StaticLocationScreenCoordinatorAction {
    case close
}

final class StaticLocationScreenCoordinator: CoordinatorProtocol {
    private let parameters: StaticLocationScreenCoordinatorParameters
    private let viewModel: StaticLocationScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<StaticLocationScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<StaticLocationScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: StaticLocationScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = StaticLocationScreenViewModel(interactionMode: parameters.interactionMode,
                                                  mapURLBuilder: parameters.mapURLBuilder,
                                                  timelineController: parameters.timelineController,
                                                  analytics: parameters.analytics,
                                                  userIndicatorController: parameters.userIndicatorController)
    }
    
    // MARK: - Public
    
    func start() {
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .close:
                actionsSubject.send(.close)
            case .openSystemSettings:
                parameters.appMediator.openAppSettings()
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(StaticLocationScreen(context: viewModel.context))
    }
}
