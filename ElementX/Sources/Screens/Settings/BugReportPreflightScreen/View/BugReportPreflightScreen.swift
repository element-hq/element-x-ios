//
// Copyright 2025 Element Creations Ltd.
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
            reportSection
            diagnosticsSection
            actionsSection
        }
        .compoundList()
        .navigationTitle(L10n.commonReportAProblem)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: isSharePresented) {
            if let shareText = context.viewState.shareText {
                AppActivityView(activityItems: [shareText],
                                onCancel: { context.send(viewAction: .dismissShare) },
                                onComplete: { _ in context.send(viewAction: .dismissShare) })
            }
        }
    }

    private var isSharePresented: Binding<Bool> {
        Binding(get: { context.viewState.shareText != nil },
                set: { if !$0 { context.send(viewAction: .dismissShare) } })
    }

    // MARK: - Private

    private var reportSection: some View {
        Section {
            ListRow(kind: .custom {
                VStack(alignment: .leading, spacing: 16) {
                    textField("Summary", text: $context.summary)
                    textField("Steps to Reproduce", text: $context.stepsToReproduce)
                    textField("Expected Result", text: $context.expectedResult)
                    textField("Actual Result", text: $context.actualResult)
                }
                .padding(.horizontal, ListRowPadding.horizontal)
                .padding(.vertical, 12)
            })
        } header: {
            Text("Bug Report")
                .compoundListSectionHeader()
        }
    }

    private var diagnosticsSection: some View {
        Section {
            ListRow(kind: .custom {
                VStack(alignment: .leading, spacing: 8) {
                    if context.viewState.isLoadingDiagnostics {
                        ProgressView()
                            .frame(maxWidth: .infinity, alignment: .center)
                    } else if let diagnostics = context.viewState.diagnosticsText {
                        Text(diagnostics)
                            .font(.compound.bodySM)
                            .foregroundColor(.compound.textSecondary)
                            .textSelection(.enabled)
                    }
                }
                .padding(.horizontal, ListRowPadding.horizontal)
                .padding(.vertical, 12)
            })
        } header: {
            Text("Diagnostics")
                .compoundListSectionHeader()
        }
    }

    private var actionsSection: some View {
        Section {
            ListRow(label: .default(title: "Copy to Clipboard",
                                    icon: \.copy),
                    kind: .button {
                        context.send(viewAction: .copyToClipboard)
                    })

            ListRow(label: .default(title: "Share",
                                    icon: \.shareIos),
                    kind: .button {
                        context.send(viewAction: .share)
                    })
        }
    }

    private func textField(_ title: String, text: Binding<String>) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.compound.bodySMSemibold)
                .foregroundColor(.compound.textPrimary)
            TextField(title, text: text, axis: .vertical)
                .font(.compound.bodySM)
                .lineLimit(3...6)
                .textFieldStyle(.roundedBorder)
        }
    }
}
