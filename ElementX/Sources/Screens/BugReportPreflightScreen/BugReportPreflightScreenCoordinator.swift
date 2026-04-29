//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI
import UIKit

struct BugReportPreflightScreenCoordinatorParameters {
    let diagnosticsProvider: DiagnosticsProviding
    let userIndicatorController: UserIndicatorControllerProtocol
}

final class BugReportPreflightScreenCoordinator: CoordinatorProtocol {
    private let parameters: BugReportPreflightScreenCoordinatorParameters
    private let viewModel: BugReportPreflightScreenViewModelProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(parameters: BugReportPreflightScreenCoordinatorParameters) {
        self.parameters = parameters
        viewModel = BugReportPreflightScreenViewModel(diagnosticsProvider: parameters.diagnosticsProvider)
    }
    
    func start() {
        guard cancellables.isEmpty else { return }
        
        viewModel.actions
            .sink { [weak self] action in
                guard let self else { return }
                
                switch action {
                case let .copyReport(report):
                    UIPasteboard.general.string = report
                    parameters.userIndicatorController.submitIndicator(.init(title: L10n.commonCopiedToClipboard))
                }
            }
            .store(in: &cancellables)
    }
    
    func stop() {
        cancellables.removeAll()
    }
    
    func toPresentable() -> AnyView {
        AnyView(BugReportPreflightScreen(context: viewModel.context))
    }
}
