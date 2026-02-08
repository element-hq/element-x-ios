//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias BugReportPreflightScreenViewModelType = StateStoreViewModelV2<BugReportPreflightScreenViewState, BugReportPreflightScreenViewAction>

class BugReportPreflightScreenViewModel: BugReportPreflightScreenViewModelType, BugReportPreflightScreenViewModelProtocol {
    private let diagnosticsProvider: DiagnosticsProviding
    private var diagnosticsTask: Task<Void, Never>?

    init(diagnosticsProvider: DiagnosticsProviding) {
        self.diagnosticsProvider = diagnosticsProvider

        let bindings = BugReportPreflightScreenViewStateBindings(summary: "",
                                                                 stepsToReproduce: "",
                                                                 expectedResult: "",
                                                                 actualResult: "")
        super.init(initialViewState: .init(diagnosticsText: nil,
                                           isLoadingDiagnostics: true,
                                           shareText: nil,
                                           bindings: bindings))

        loadDiagnostics()
    }

    override func process(viewAction: BugReportPreflightScreenViewAction) {
        switch viewAction {
        case .copyToClipboard:
            UIPasteboard.general.string = buildReport()
        case .share:
            state.shareText = buildReport()
        case .dismissShare:
            state.shareText = nil
        }
    }

    func stop() {
        diagnosticsTask?.cancel()
        diagnosticsTask = nil
    }

    // MARK: - Static

    static func buildReport(summary: String,
                            stepsToReproduce: String,
                            expectedResult: String,
                            actualResult: String,
                            diagnosticsText: String?) -> String {
        var sections = [String]()

        sections.append("## Summary\n\(summary)")
        sections.append("## Steps to Reproduce\n\(stepsToReproduce)")
        sections.append("## Expected Result\n\(expectedResult)")
        sections.append("## Actual Result\n\(actualResult)")

        if let diagnosticsText {
            let redacted = Redactor.redact(diagnosticsText)
            sections.append("## Diagnostics\n\(redacted)")
        }

        return sections.joined(separator: "\n\n")
    }

    // MARK: - Private

    private func buildReport() -> String {
        Self.buildReport(summary: state.bindings.summary,
                         stepsToReproduce: state.bindings.stepsToReproduce,
                         expectedResult: state.bindings.expectedResult,
                         actualResult: state.bindings.actualResult,
                         diagnosticsText: state.diagnosticsText)
    }

    private func loadDiagnostics() {
        diagnosticsTask = Task { [weak self, diagnosticsProvider] in
            let diagnostics = await diagnosticsProvider.collectDiagnostics()

            guard !Task.isCancelled else { return }

            await MainActor.run {
                self?.state.diagnosticsText = diagnostics.formattedString
                self?.state.isLoadingDiagnostics = false
            }
        }
    }
}
