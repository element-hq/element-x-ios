//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

struct DiagnosticsReportScreenCoordinatorParameters {
    let userSession: UserSessionProtocol?
    let userIndicatorController: UserIndicatorControllerProtocol
}

final class DiagnosticsReportScreenCoordinator: CoordinatorProtocol {
    private let parameters: DiagnosticsReportScreenCoordinatorParameters
    private let viewModel: DiagnosticsReportScreenViewModelProtocol
    
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: DiagnosticsReportScreenCoordinatorParameters) {
        self.parameters = parameters
        
        viewModel = DiagnosticsReportScreenViewModel(userSession: parameters.userSession,
                                                     userIndicatorController: parameters.userIndicatorController)
    }
    
    func start() {
        viewModel.actionsPublisher.sink { [weak self] action in
            MXLog.info("Coordinator: received view model action: \(action)")
            
            guard let self else { return }
            // No actions to handle currently - screen is self-contained
        }
        .store(in: &cancellables)
    }
    
    func toPresentable() -> AnyView {
        AnyView(DiagnosticsReportScreen(context: viewModel.context))
    }
}
