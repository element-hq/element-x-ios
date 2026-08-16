//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ManageStorageScreenCoordinatorParameters {
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum ManageStorageScreenCoordinatorAction {
    /// The whole state store is to be cleared: the app clears its caches and restarts.
    case clearCache
}

final class ManageStorageScreenCoordinator: CoordinatorProtocol {
    private let viewModel: ManageStorageScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<ManageStorageScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ManageStorageScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: ManageStorageScreenCoordinatorParameters) {
        viewModel = ManageStorageScreenViewModel(clientProxy: parameters.clientProxy,
                                                 userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            switch action {
            case .clearCache:
                actionsSubject.send(.clearCache)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(ManageStorageScreen(context: viewModel.context))
    }
}
