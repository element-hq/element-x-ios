//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import UIKit

struct BugReportPreflightScreen: View {
    // MARK: - Public Properties

    @Bindable var context: BugReportPreflightScreenViewModel.Context

    // MARK: - Body

    var body: some View {
        Form {
            textEditorSection(text: $context.summary, header: UntranslatedL10n.bugReportPreflightFieldSummary)
            textEditorSection(text: $context.steps, header: UntranslatedL10n.bugReportPreflightFieldSteps)
            textEditorSection(text: $context.expected, header: UntranslatedL10n.bugReportPreflightFieldExpected)
            textEditorSection(text: $context.actual, header: UntranslatedL10n.bugReportPreflightFieldActual)
            diagnosticsSection()
            actionsSection()
        }
        .compoundList()
        .navigationTitle(UntranslatedL10n.bugReportPreflightTitle)
        .navigationBarTitleDisplayMode(.inline)
        .contentShape(.rect)
        .onTapGesture {
            endEditing()
        }
        .onAppear {
            context.send(viewAction: .screenAppeared)
        }
        .onDisappear {
            context.send(viewAction: .screenDisappeared)
        }
        .sheet(isPresented: $context.isShareSheetPresented) {
            shareSheet()
        }
    }

    // MARK: - Subviews

    private func textEditorSection(text: Binding<String>, header: String) -> some View {
        Section {
            TextEditor(text: text)
                .font(.compound.bodySM)
                .foregroundStyle(.compound.textPrimary)
                .frame(minHeight: 50)
                .padding(.vertical, 4)
                .onChange(of: text.wrappedValue) { _, _ in
                    context.send(viewAction: .reportChanged)
                }
        } header: {
            Text(header)
                .compoundListSectionHeader()
        }
    }

    private func diagnosticsSection() -> some View {
        Section {
            Text(context.viewState.diagnosticsText)
                .font(.compound.bodySM.monospaced())
                .foregroundStyle(.compound.textSecondary)
                .textSelection(.enabled)
                .padding(.vertical, 4)
        } header: {
            HStack(spacing: 8) {
                Text(UntranslatedL10n.bugReportPreflightDiagnostics)
                    .compoundListSectionHeader()
                if context.viewState.isDiagnosticsLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
        }
    }

    private func actionsSection() -> some View {
        Section {
            ListRow(label: .default(title: L10n.actionCopy,
                                    icon: \.copy),
                    kind: .button {
                        UIPasteboard.general.string = context.viewState.reportText
                    })
                    .disabled(context.viewState.isDiagnosticsLoading)

            ListRow(label: .default(title: L10n.actionShare,
                                    icon: \.shareIos),
                    kind: .button {
                        context.isShareSheetPresented = true
                    })
                    .disabled(context.viewState.isDiagnosticsLoading)
        }
    }

    private func shareSheet() -> some View {
        AppActivityView(activityItems: [context.viewState.reportText])
            .edgesIgnoringSafeArea(.bottom)
            .presentationDetents([.medium, .large])
    }

    // MARK: - Private Methods

    private func endEditing() {
        UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                        to: nil,
                                        from: nil,
                                        for: nil)
    }
}

// MARK: - Previews

struct BugReportPreflightScreen_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        NavigationStack {
            BugReportPreflightScreen(context: BugReportPreflightScreenViewModel(diagnosticsProvider: SystemDiagnosticsProvider(),
                                                                                redactor: Redactor(),
                                                                                reportBuilder: BugReportPreflightReportBuilder()).context)
        }
    }
}
