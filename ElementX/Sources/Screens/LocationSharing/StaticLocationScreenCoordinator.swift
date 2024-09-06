//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

struct StaticLocationScreenCoordinatorParameters {
    let interactionMode: StaticLocationInteractionMode
    let appMediator: AppMediatorProtocol
}

enum StaticLocationScreenCoordinatorAction {
    case close
    case selectedLocation(GeoURI, isUserLocation: Bool)
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
        
        viewModel = StaticLocationScreenViewModel(interactionMode: parameters.interactionMode)
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
            case .sendLocation(let geoURI, let isUserLocation):
                actionsSubject.send(.selectedLocation(geoURI, isUserLocation: isUserLocation))
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(StaticLocationScreen(context: viewModel.context))
    }
}
