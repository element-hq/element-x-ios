//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

typealias BugReportPreflightScreenViewModelType = StateStoreViewModelV2<BugReportPreflightScreenViewState, BugReportPreflightScreenViewAction>

final class BugReportPreflightScreenViewModel: BugReportPreflightScreenViewModelType, @MainActor BugReportPreflightScreenViewModelProtocol {
    // MARK: - Private Properties

    private let diagnosticsProvider: DiagnosticsProviding
    private let redactor: Redacting
    private let reportBuilder: BugReportPreflightReportBuilding
    private var diagnosticsTask: Task<Void, Never>?

    // MARK: - Initializers

    init(diagnosticsProvider: DiagnosticsProviding,
         redactor: Redacting,
         reportBuilder: BugReportPreflightReportBuilding) {
        self.diagnosticsProvider = diagnosticsProvider
        self.redactor = redactor
        self.reportBuilder = reportBuilder

        let initialDiagnostics = L10n.commonLoading
        let initialReport = reportBuilder.buildReport(summary: "",
                                                      steps: "",
                                                      expected: "",
                                                      actual: "",
                                                      diagnostics: initialDiagnostics)
        super.init(initialViewState: .init(diagnosticsText: initialDiagnostics,
                                           isDiagnosticsLoading: true,
                                           reportText: initialReport))
    }

    deinit {
        diagnosticsTask?.cancel()
    }

    // MARK: - Public Methods

    override func process(viewAction: BugReportPreflightScreenViewAction) {
        switch viewAction {
        case .screenAppeared: loadDiagnostics()
        case .screenDisappeared: cancelDiagnostics()
        case .reportChanged: rebuildReport()
        }
    }

    // MARK: - Private Methods

    private func loadDiagnostics() {
        cancelDiagnostics()
        state.isDiagnosticsLoading = true
        state.diagnosticsText = L10n.commonLoading
        rebuildReport()
        diagnosticsTask = Task {
            let diagnostics = await diagnosticsProvider.generateDiagnostics()

            guard !Task.isCancelled else { return }

            let redactedText = redactor.redact(diagnostics)

            await MainActor.run {
                state.isDiagnosticsLoading = false
                state.diagnosticsText = redactedText
                rebuildReport()
            }
        }
    }

    private func cancelDiagnostics() {
        diagnosticsTask?.cancel()
        diagnosticsTask = nil
    }

    private func rebuildReport() {
        state.reportText = reportBuilder.buildReport(summary: state.bindings.summary,
                                                     steps: state.bindings.steps,
                                                     expected: state.bindings.expected,
                                                     actual: state.bindings.actual,
                                                     diagnostics: state.diagnosticsText)
    }
}
