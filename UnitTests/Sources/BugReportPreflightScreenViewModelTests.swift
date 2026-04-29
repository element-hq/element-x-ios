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
    func initialState() {
        let viewModel = BugReportPreflightScreenViewModel(diagnosticsProvider: StaticDiagnosticsProvider(diagnostics: "OS: iOS 18.0"))
        let context = viewModel.context
        
        #expect(context.viewState.isLoadingDiagnostics)
        #expect(context.viewState.reportTemplate.contains(UntranslatedL10n.screenBugReportPreflightTemplateSummary))
        #expect(context.viewState.diagnosticsText == UntranslatedL10n.screenBugReportPreflightDiagnosticsLoading)
    }
    
    @Test
    func loadDiagnostics() async throws {
        let viewModel = BugReportPreflightScreenViewModel(diagnosticsProvider: StaticDiagnosticsProvider(diagnostics: "OS: iOS 18.0"))
        let context = viewModel.context
        
        let deferred = deferFulfillment(context.observe(\.viewState.isLoadingDiagnostics)) { !$0 }
        
        context.send(viewAction: .loadDiagnostics)
        try await deferred.fulfill()
        
        #expect(context.viewState.diagnosticsText == "OS: iOS 18.0")
        #expect(context.viewState.fullReport.contains("OS: iOS 18.0"))
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
