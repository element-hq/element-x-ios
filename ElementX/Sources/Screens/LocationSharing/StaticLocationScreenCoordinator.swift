//
// Copyright 2023 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import Combine
import SwiftUI

struct StaticLocationScreenCoordinatorParameters {
    let interactionMode: StaticLocationInteractionMode
}

enum StaticLocationScreenCoordinatorAction {
    case close
    case selectedLocation(GeoURI, isUserLocation: Bool)
}

final class StaticLocationScreenCoordinator: CoordinatorProtocol {
    let parameters: StaticLocationScreenCoordinatorParameters
    let viewModel: StaticLocationScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<StaticLocationScreenCoordinatorAction, Never> = .init()
    private var cancellables: Set<AnyCancellable> = .init()
    
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
                guard let url = URL(string: UIApplication.openSettingsURLString),
                      UIApplication.shared.canOpenURL(url) else { return }
                UIApplication.shared.open(url)
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
