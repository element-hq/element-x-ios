//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct LocationSharingScreenCoordinatorParameters {
    let interactionMode: LocationSharingInteractionMode
    let mapURLBuilder: MapTilerURLBuilderProtocol
    let liveLocationSharingEnabled: Bool
    let timelineController: TimelineControllerProtocol
    let appMediator: AppMediatorProtocol
    let analytics: AnalyticsService
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum LocationSharingScreenCoordinatorAction {
    case close
}

final class LocationSharingScreenCoordinator: CoordinatorProtocol {
    private let parameters: LocationSharingScreenCoordinatorParameters
    private let viewModel: LocationSharingScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<LocationSharingScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<LocationSharingScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: LocationSharingScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = LocationSharingScreenViewModel(interactionMode: parameters.interactionMode,
                                                   mapURLBuilder: parameters.mapURLBuilder,
                                                   liveLocationSharingEnabled: parameters.liveLocationSharingEnabled,
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
        AnyView(LocationSharingScreen(context: viewModel.context))
    }
}
