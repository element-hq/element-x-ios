//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct DeveloperOptionsScreenParameters {
    let settings: DeveloperOptionsScreenSettings
    let appHooks: AppHooks
    let clientProxy: ClientProxyProtocol?
}

enum DeveloperOptionsScreenCoordinatorAction {
    case clearCache
}

final class DeveloperOptionsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: DeveloperOptionsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<DeveloperOptionsScreenCoordinatorAction, Never> = .init()
    private var cancellables = Set<AnyCancellable>()
    
    var actions: AnyPublisher<DeveloperOptionsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: DeveloperOptionsScreenParameters) {
        viewModel = DeveloperOptionsScreenViewModel(settings: parameters.settings,
                                                    appHooks: parameters.appHooks,
                                                    clientProxy: parameters.clientProxy)
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .clearCache:
                    actionsSubject.send(.clearCache)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(DeveloperOptionsScreen(context: viewModel.context))
    }
}
