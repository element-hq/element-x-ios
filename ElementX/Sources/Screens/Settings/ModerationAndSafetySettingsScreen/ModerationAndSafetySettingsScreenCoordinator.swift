//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct ModerationAndSafetySettingsScreenCoordinatorParameters {
    let userSession: UserSessionProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum ModerationAndSafetySettingsScreenCoordinatorAction {
    case blockedUsers
}

final class ModerationAndSafetySettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: ModerationAndSafetySettingsScreenViewModelProtocol
    
    private let actionsSubject: PassthroughSubject<ModerationAndSafetySettingsScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<ModerationAndSafetySettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: ModerationAndSafetySettingsScreenCoordinatorParameters) {
        viewModel = ModerationAndSafetySettingsScreenViewModel(userSession: parameters.userSession,
                                                               userIndicatorController: parameters.userIndicatorController)
        
        viewModel.actionsPublisher
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case .blockedUsers:
                    actionsSubject.send(.blockedUsers)
                }
            }
            .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(ModerationAndSafetySettingsScreen(context: viewModel.context))
    }
}
