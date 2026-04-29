//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import SwiftUI

typealias BugReportPreflightScreenViewModelType = StateStoreViewModelV2<BugReportPreflightScreenViewState, BugReportPreflightScreenViewAction>

class BugReportPreflightScreenViewModel: BugReportPreflightScreenViewModelType, BugReportPreflightScreenViewModelProtocol {
    private let diagnosticsProvider: DiagnosticsProviding
    
    private var actionsSubject: PassthroughSubject<BugReportPreflightScreenViewModelAction, Never> = .init()
    @CancellableTask private var diagnosticsTask: Task<Void, Never>?
    
    private var hasRequestedDiagnostics = false
    
    var actions: AnyPublisher<BugReportPreflightScreenViewModelAction, Never> {
        actionsSubject.eraseToAnyPublisher()
    }
    
    init(diagnosticsProvider: DiagnosticsProviding) {
        self.diagnosticsProvider = diagnosticsProvider
        
        super.init(initialViewState: .init(reportTemplate: Self.reportTemplate,
                                           diagnosticsText: UntranslatedL10n.screenBugReportPreflightDiagnosticsLoading))
    }
    
    override func process(viewAction: BugReportPreflightScreenViewAction) {
        switch viewAction {
        case .loadDiagnostics:
            guard !hasRequestedDiagnostics else { return }
            
            hasRequestedDiagnostics = true
            diagnosticsTask = Task { await loadDiagnostics() }
        case .cancelDiagnosticsLoading:
            diagnosticsTask = nil
        case .copyReport:
            guard !state.isLoadingDiagnostics else { return }
            actionsSubject.send(.copyReport(state.fullReport))
        }
    }
    
    private func loadDiagnostics() async {
        do {
            let diagnostics = try await diagnosticsProvider.makeDiagnostics()
            guard !Task.isCancelled else { return }
            
            state.diagnosticsText = diagnostics
            state.isLoadingDiagnostics = false
        } catch is CancellationError {
            MXLog.verbose("Cancelled bug report diagnostics generation")
        } catch {
            MXLog.error("Failed generating diagnostics: \(error)")
            state.diagnosticsText = UntranslatedL10n.screenBugReportPreflightDiagnosticsUnavailable
            state.isLoadingDiagnostics = false
        }
    }
    
    private static var reportTemplate: String {
        """
        \(UntranslatedL10n.screenBugReportPreflightTemplateSummary):

        \(UntranslatedL10n.screenBugReportPreflightTemplateSteps):
        1.
        2.

        \(UntranslatedL10n.screenBugReportPreflightTemplateExpected):

        \(UntranslatedL10n.screenBugReportPreflightTemplateActual):
        """
    }
}
