//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct AdvancedSettingsScreenCoordinatorParameters {
    let appSettings: AppSettings
    let analytics: AnalyticsServiceProtocol
    let clientProxy: ClientProxyProtocol
    let userIndicatorController: UserIndicatorControllerProtocol
}

enum AdvancedSettingsScreenCoordinatorAction {
    case manageStorage
}

final class AdvancedSettingsScreenCoordinator: CoordinatorProtocol {
    private var viewModel: AdvancedSettingsScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    private let actionsSubject: PassthroughSubject<AdvancedSettingsScreenCoordinatorAction, Never> = .init()
    var actionsPublisher: AnyPublisher<AdvancedSettingsScreenCoordinatorAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(parameters: AdvancedSettingsScreenCoordinatorParameters) {
        viewModel = AdvancedSettingsScreenViewModel(advancedSettings: parameters.appSettings,
                                                    analytics: parameters.analytics,
                                                    clientProxy: parameters.clientProxy,
                                                    userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .manageStorage:
                actionsSubject.send(.manageStorage)
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(AdvancedSettingsScreen(context: viewModel.context))
    }
}
