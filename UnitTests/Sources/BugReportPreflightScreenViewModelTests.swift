//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct BugReportPreflightScreenViewModelTests {
    enum TestError: Error {
        case failed
    }
    
    @Test
    func copyReport() async throws {
        let viewModel = BugReportPreflightScreenViewModel(diagnosticsProvider: StaticDiagnosticsProvider(diagnostics: "OS: iOS 18.0"))
        let context = viewModel.context
        
        let loadingDeferred = deferFulfillment(context.observe(\.viewState.isLoadingDiagnostics)) { !$0 }
        context.send(viewAction: .loadDiagnostics)
        try await loadingDeferred.fulfill()
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .copyReport:
                true
            }
        }
        
        context.send(viewAction: .copyReport)
        let action = try await deferred.fulfill()
        
        switch action {
        case let .copyReport(report):
            #expect(report.contains(UntranslatedL10n.screenBugReportPreflightTemplateSummary))
            #expect(report.contains("OS: iOS 18.0"))
            #expect(report.contains(UntranslatedL10n.screenBugReportPreflightDiagnosticsTitle))
        }
    }
    
    @Test
    func loadDiagnosticsFailure() async throws {
        let viewModel = BugReportPreflightScreenViewModel(diagnosticsProvider: FailingDiagnosticsProvider())
        let context = viewModel.context
        
        let deferred = deferFulfillment(context.observe(\.viewState.isLoadingDiagnostics)) { !$0 }
        
        context.send(viewAction: .loadDiagnostics)
        try await deferred.fulfill()
        
        #expect(context.viewState.diagnosticsText == UntranslatedL10n.screenBugReportPreflightDiagnosticsUnavailable)
    }
    
    @Test
    func editingReportTemplate() async throws {
        let viewModel = BugReportPreflightScreenViewModel(diagnosticsProvider: StaticDiagnosticsProvider(diagnostics: "OS: iOS 18.0"))
        let context = viewModel.context
        
        let originalTemplate = context.viewState.reportTemplate
        #expect(originalTemplate.contains(UntranslatedL10n.screenBugReportPreflightTemplateSummary))
        
        let editedTemplate = """
        Summary: App crashes on launch after upgrade.

        Steps:
        1. Open the app
        2. Wait 2 seconds

        Expected: App opens normally.
        Actual: App crashes.
        """
        
        context.reportTemplate = editedTemplate
        
        #expect(context.viewState.reportTemplate == editedTemplate)
        #expect(context.viewState.fullReport.contains(editedTemplate))
        #expect(!context.viewState.fullReport.contains(originalTemplate))
        
        let loadingDeferred = deferFulfillment(context.observe(\.viewState.isLoadingDiagnostics)) { !$0 }
        context.send(viewAction: .loadDiagnostics)
        try await loadingDeferred.fulfill()
        
        let copyDeferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .copyReport:
                true
            }
        }
        
        context.send(viewAction: .copyReport)
        let action = try await copyDeferred.fulfill()
        
        switch action {
        case let .copyReport(report):
            #expect(report.contains(editedTemplate))
            #expect(report.contains("OS: iOS 18.0"))
        }
    }
    
    @Test
    func deterministicReportFormat() async throws {
        let diagnostics = """
        App: Element X
        Version: 1.23.4 (567)
        OS: iOS 18.0
        """
        
        func generateReport() async throws -> String {
            let viewModel = BugReportPreflightScreenViewModel(diagnosticsProvider: StaticDiagnosticsProvider(diagnostics: diagnostics))
            let context = viewModel.context
            
            let deferred = deferFulfillment(context.observe(\.viewState.isLoadingDiagnostics)) { !$0 }
            context.send(viewAction: .loadDiagnostics)
            try await deferred.fulfill()
            
            return context.viewState.fullReport
        }
        
        let firstRun = try await generateReport()
        let secondRun = try await generateReport()
        
        #expect(firstRun == secondRun, "Same input must produce the same fullReport on every run")
        
        let expectedReport = """
        \(UntranslatedL10n.screenBugReportPreflightTemplateSummary):

        \(UntranslatedL10n.screenBugReportPreflightTemplateSteps):
        1.
        2.

        \(UntranslatedL10n.screenBugReportPreflightTemplateExpected):

        \(UntranslatedL10n.screenBugReportPreflightTemplateActual):

        \(UntranslatedL10n.screenBugReportPreflightDiagnosticsTitle):
        \(diagnostics)
        """
        
        #expect(firstRun == expectedReport, "fullReport must match the canonical snapshot for the given inputs")
    }
    
    @Test
    func cancelDiagnosticsLoading() async throws {
        let provider = HangingDiagnosticsProvider()
        let viewModel = BugReportPreflightScreenViewModel(diagnosticsProvider: provider)
        let context = viewModel.context
        
        let deferred = deferFailure(context.observe(\.viewState.isLoadingDiagnostics),
                                    timeout: .seconds(1)) { !$0 }
        
        context.send(viewAction: .loadDiagnostics)
        await provider.waitUntilStarted()
        context.send(viewAction: .cancelDiagnosticsLoading)
        try await deferred.fulfill()
        
        for _ in 0..<50 {
            if await provider.wasCancelled() {
                break
            }
            
            await Task.yield()
        }
        
        #expect(await provider.wasCancelled())
    }
}

private struct StaticDiagnosticsProvider: DiagnosticsProviding {
    let diagnostics: String
    
    func makeDiagnostics() async throws -> String {
        diagnostics
    }
}

private struct FailingDiagnosticsProvider: DiagnosticsProviding {
    func makeDiagnostics() async throws -> String {
        throw BugReportPreflightScreenViewModelTests.TestError.failed
    }
}

private actor HangingDiagnosticsProvider: DiagnosticsProviding {
    private var hasStarted = false
    private var hasCancelled = false
    
    func makeDiagnostics() async throws -> String {
        try await withTaskCancellationHandler(operation: {
            hasStarted = true
            try await Task.sleep(for: .seconds(60))
            return "This should never finish"
        }, onCancel: {
            Task { await self.markCancelled() }
        })
    }
    
    func waitUntilStarted() async {
        while !hasStarted {
            await Task.yield()
        }
    }
    
    func wasCancelled() -> Bool {
        hasCancelled
    }
    
    private func markCancelled() {
        hasCancelled = true
    }
}
