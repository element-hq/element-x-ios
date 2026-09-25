//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct LabsScreenCoordinatorParameters {
    let userSettings: UserSettings
}

enum LabsScreenCoordinatorAction {
    case clearCache
}

final class LabsScreenCoordinator: CoordinatorProtocol {
    private let viewModel: LabsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<LabsScreenCoordinatorAction, Never> = .init()
    var actions: AnyPublisher<LabsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: LabsScreenCoordinatorParameters) {
        viewModel = LabsScreenViewModel(labsOptions: parameters.userSettings.app)
    }
    
    func start() {
        viewModel
            .actionsPublisher
            .sink { [weak self] action in
                switch action {
                case .clearCache:
                    self?.actionsSubject.send(.clearCache)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(LabsScreen(context: viewModel.context))
    }
}
