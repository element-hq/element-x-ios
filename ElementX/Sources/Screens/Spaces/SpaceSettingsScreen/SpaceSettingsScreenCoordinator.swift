//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct SpaceSettingsScreenCoordinatorParameters { }

enum SpaceSettingsScreenCoordinatorAction { }

final class SpaceSettingsScreenCoordinator: CoordinatorProtocol {
    private let parameters: SpaceSettingsScreenCoordinatorParameters
    private let viewModel: SpaceSettingsScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
 
    private let actionsSubject: PassthroughSubject<SpaceSettingsScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<SpaceSettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: SpaceSettingsScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = SpaceSettingsScreenViewModel()
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action { }
        }
        .store(in: &cancellables)
    }
        
    func toPresentable() -> AnyView {
        AnyView(SpaceSettingsScreen(context: viewModel.context))
    }
}
