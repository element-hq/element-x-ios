//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct BugReportPreflightScreenCoordinatorParameters {
    let diagnosticsProvider: DiagnosticsProviding
    let redactor: Redactor
    let reportBuilder: BugReportPreflightReportBuilder
}

final class BugReportPreflightScreenCoordinator: CoordinatorProtocol {
    // MARK: - Private Properties

    private let viewModel: BugReportPreflightScreenViewModelProtocol

    // MARK: - Initializers

    init(parameters: BugReportPreflightScreenCoordinatorParameters) {
        viewModel = BugReportPreflightScreenViewModel(diagnosticsProvider: parameters.diagnosticsProvider,
                                                      redactor: parameters.redactor,
                                                      reportBuilder: parameters.reportBuilder)
    }

    // MARK: - Public Methods

    func toPresentable() -> AnyView {
        AnyView(BugReportPreflightScreen(context: viewModel.context))
    }
}
