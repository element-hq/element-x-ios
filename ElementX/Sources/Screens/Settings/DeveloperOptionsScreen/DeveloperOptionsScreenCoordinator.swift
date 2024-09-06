//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import SwiftUI

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
    
    init(isUsingNativeSlidingSync: Bool) {
        viewModel = DeveloperOptionsScreenViewModel(developerOptions: ServiceLocator.shared.settings,
                                                    elementCallBaseURL: ServiceLocator.shared.settings.elementCallBaseURL,
                                                    isUsingNativeSlidingSync: isUsingNativeSlidingSync)
        
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
