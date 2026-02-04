//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ReportProblemScreen: View {
    @Bindable var context: ReportProblemScreenViewModel.Context

    var body: some View {
        Form {
            Section {
                ListRow(kind: .custom {
                    TextField(text: $context.problemDescription, axis: .vertical) {
                        Text(L10n.screenReportProblemDescriptionLabel)
                            .compoundTextFieldPlaceholder()
                    }
                    .tint(.compound.iconAccentTertiary)
                    .padding(.horizontal, ListRowPadding.horizontal)
                    .padding(.vertical, ListRowPadding.vertical)
                })
            } footer: {
                Text(L10n.screenReportProblemDescriptionPlaceholder)
                    .compoundListSectionFooter()
            }

            Section {
                Text(context.viewState.diagnosticInfo)
                    .font(.system(.caption, design: .monospaced))
                    .textSelection(.enabled)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            } header: {
                Text(L10n.screenReportProblemDiagnosticInfoHeader)
                    .compoundListSectionHeader()
            }

            Section {
                ListRow(label: .default(title: L10n.actionCopy, icon: \.copy),
                        kind: .button {
                            context.send(viewAction: .copyToClipboard)
                        })

                ListRow(label: .default(title: L10n.actionShare, icon: \.shareIos),
                        kind: .button {
                            context.send(viewAction: .share)
                        })
            }
        }
        .compoundList()
        .navigationTitle(L10n.commonReportAProblem)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $context.showShareSheet) {
            AppActivityView(activityItems: [context.viewState.reportTextForSharing])
        }
    }
}
