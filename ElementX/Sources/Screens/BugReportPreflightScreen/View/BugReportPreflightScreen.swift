//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct BugReportPreflightScreen: View {
    @Bindable var context: BugReportPreflightScreenViewModel.Context
    
    var body: some View {
        Form {
            templateSection
            diagnosticsSection
        }
        .compoundList()
        .navigationTitle(L10n.commonReportAProblem)
        .navigationBarTitleDisplayMode(.inline)
        .safeAreaInset(edge: .bottom) {
            actionButtons
        }
        .task {
            context.send(viewAction: .loadDiagnostics)
        }
        .onDisappear {
            context.send(viewAction: .cancelDiagnosticsLoading)
        }
    }
    
    private var templateSection: some View {
        Section(UntranslatedL10n.screenBugReportPreflightTemplateTitle) {
            TextEditor(text: $context.reportTemplate)
                .font(.compound.bodyMD)
                .foregroundStyle(.compound.textPrimary)
                .scrollContentBackground(.hidden)
                .frame(minHeight: 160)
                .padding(8)
                .background(Color.compound.bgSubtleSecondaryLevel0)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier(A11yIdentifiers.bugReportPreflightScreen.template)
        }
    }
    
    private var diagnosticsSection: some View {
        Section(UntranslatedL10n.screenBugReportPreflightDiagnosticsTitle) {
            if context.viewState.isLoadingDiagnostics {
                HStack(spacing: 12) {
                    ProgressView()
                    Text(UntranslatedL10n.screenBugReportPreflightDiagnosticsLoading)
                        .font(.compound.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(16)
                .background(Color.compound.bgSubtleSecondaryLevel0)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .accessibilityIdentifier(A11yIdentifiers.bugReportPreflightScreen.diagnostics)
            } else {
                contentBox(context.viewState.diagnosticsText,
                           font: .compound.bodySM.monospaced(),
                           accessibilityIdentifier: A11yIdentifiers.bugReportPreflightScreen.diagnostics)
            }
        }
    }
    
    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button {
                context.send(viewAction: .copyReport)
            } label: {
                Label(L10n.actionCopy, icon: \.copy)
            }
            .buttonStyle(.compound(.primary))
            .disabled(context.viewState.isLoadingDiagnostics)
            .accessibilityIdentifier(A11yIdentifiers.bugReportPreflightScreen.copy)
            
            ShareLink(item: context.viewState.fullReport) {
                Label(L10n.actionShare, icon: \.shareIos)
            }
            .buttonStyle(.compound(.secondary))
            .disabled(context.viewState.isLoadingDiagnostics)
            .accessibilityIdentifier(A11yIdentifiers.bugReportPreflightScreen.share)
        }
        .padding(.horizontal, 16)
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(Color.compound.bgCanvasDefault)
    }
    
    private func contentBox(_ text: String, font: Font, accessibilityIdentifier: String) -> some View {
        Text(text)
            .font(font)
            .foregroundStyle(.compound.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .textSelection(.enabled)
            .padding(16)
            .background(Color.compound.bgSubtleSecondaryLevel0)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .accessibilityIdentifier(accessibilityIdentifier)
    }
}

// MARK: - Previews

struct BugReportPreflightScreen_Previews: PreviewProvider, TestablePreview {
    static let loadingViewModel = makeLoadingViewModel()
    static let loadedViewModel = makeLoadedViewModel()
    
    static var previews: some View {
        ElementNavigationStack {
            BugReportPreflightScreen(context: loadingViewModel.context)
        }
        .previewDisplayName("Loading")
        
        ElementNavigationStack {
            BugReportPreflightScreen(context: loadedViewModel.context)
        }
        .previewDisplayName("Loaded")
    }
    
    static func makeLoadingViewModel() -> BugReportPreflightScreenViewModel {
        BugReportPreflightScreenViewModel(diagnosticsProvider: LoadingPreviewDiagnosticsProvider())
    }
    
    static func makeLoadedViewModel() -> BugReportPreflightScreenViewModel {
        let viewModel = BugReportPreflightScreenViewModel(diagnosticsProvider: LoadedPreviewDiagnosticsProvider())
        viewModel.state.diagnosticsText = LoadedPreviewDiagnosticsProvider.diagnostics
        viewModel.state.isLoadingDiagnostics = false
        return viewModel
    }
}

private struct LoadingPreviewDiagnosticsProvider: DiagnosticsProviding {
    func makeDiagnostics() async throws -> String {
        try await Task.sleep(for: .seconds(60))
        return ""
    }
}

private struct LoadedPreviewDiagnosticsProvider: DiagnosticsProviding {
    static let diagnostics = """
    App: Element X
    Version: 1.23.4 (567)
    Bundle ID: io.element.elementx
    OS: iOS 18.0
    User Agent: Element X/1.23.4 (iPhone; iOS 18.0; Scale/3.00)
    Resolved Languages: en
    Preferred Languages: en-GB
    Time Zone: Europe/London
    Generated: 2026-04-29T12:34:56.000Z
    User ID: [redacted matrix id]
    Device ID: ABCDEFG
    """
    
    func makeDiagnostics() async throws -> String {
        Self.diagnostics
    }
}
