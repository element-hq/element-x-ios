//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct DiagnosticsReportScreen: View {
    @Bindable var context: DiagnosticsReportScreenViewModel.Context
    
    var body: some View {
        Form {
            Section {
                TextEditor(text: $context.reportText)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textPrimary)
                    .frame(minHeight: 250)
                    .scrollContentBackground(.hidden)
            } header: {
                Text(UntranslatedL10n.quickDiagnosticsReportHeader)
                    .compoundListSectionHeader()
            }
            
            Section {
                ListRow(label: .default(title: L10n.actionCopy,
                                        icon: \.copy),
                        kind: .button {
                            context.send(viewAction: .copyToClipboard)
                        })
                
                ListRow(label: .default(title: L10n.actionShare,
                                        icon: \.shareIos),
                        kind: .button {
                            context.send(viewAction: .share)
                        })
            }
        }
        .compoundList()
        .navigationTitle(L10n.commonReportAProblem)
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $context.isSharePresented) {
            AppActivityView(activityItems: [context.viewState.bindings.reportText])
        }
    }
}

// MARK: - Previews

struct DiagnosticsReportScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = DiagnosticsReportScreenViewModel(userSession: nil,
                                                            userIndicatorController: UserIndicatorControllerMock())
    static var previews: some View {
        NavigationStack {
            DiagnosticsReportScreen(context: viewModel.context)
        }
    }
}
