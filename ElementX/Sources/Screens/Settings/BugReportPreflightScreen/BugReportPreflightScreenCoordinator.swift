//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct BugReportPreflightScreenCoordinatorParameters {
    let diagnosticsProvider: DiagnosticsProviding
}

final class BugReportPreflightScreenCoordinator: CoordinatorProtocol {
    private let viewModel: BugReportPreflightScreenViewModel

    init(parameters: BugReportPreflightScreenCoordinatorParameters) {
        viewModel = BugReportPreflightScreenViewModel(diagnosticsProvider: parameters.diagnosticsProvider)
    }

    func stop() {
        viewModel.stop()
    }

    func toPresentable() -> AnyView {
        AnyView(BugReportPreflightScreen(context: viewModel.context))
    }
}
