//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct NotificationSoundSelectionScreenCoordinatorParameters {
    let appSettings: AppSettings
}

final class NotificationSoundSelectionScreenCoordinator: CoordinatorProtocol {
    private let parameters: NotificationSoundSelectionScreenCoordinatorParameters
    private var viewModel: NotificationSoundSelectionScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: NotificationSoundSelectionScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = NotificationSoundSelectionScreenViewModel(appSettings: parameters.appSettings)
    }
    
    func start() {
        // Handle view model actions if needed
        viewModel.actions.sink { [weak self] action in
            guard let self else { return }
            switch action {
            case .complete:
                // Navigation handled automatically by NavigationLink
                break
            }
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(NotificationSoundSelectionScreen(context: viewModel.context))
    }
}
