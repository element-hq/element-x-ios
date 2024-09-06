//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

struct ReportContentScreen: View {
    @ObservedObject var context: ReportContentScreenViewModel.Context

    var body: some View {
        Form {
            reasonSection
            
            ignoreUserSection
        }
        .scrollDismissesKeyboard(.immediately)
        .compoundList()
        .navigationTitle(L10n.actionReportContent)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .interactiveDismissDisabled()
    }

    private var reasonSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenReportContentHint),
                    kind: .textField(text: $context.reasonText, axis: .vertical))
                .lineLimit(4, reservesSpace: true)
        } footer: {
            Text(L10n.screenReportContentExplanation)
                .compoundListSectionFooter()
        }
    }
    
    private var ignoreUserSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenReportContentBlockUser),
                    kind: .toggle($context.ignoreUser))
                .accessibilityIdentifier(A11yIdentifiers.reportContent.ignoreUser)
        } footer: {
            Text(L10n.screenReportContentBlockUserHint)
                .compoundListSectionFooter()
        }
    }

    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .cancel)
            }
        }

        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionSend) {
                context.send(viewAction: .submit)
            }
        }
    }
}

// MARK: - Previews

struct ReportContentScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = ReportContentScreenViewModel(eventID: "",
                                                        senderID: "",
                                                        roomProxy: JoinedRoomProxyMock(.init()),
                                                        clientProxy: ClientProxyMock(.init()))
    
    static var previews: some View {
        NavigationStack {
            ReportContentScreen(context: viewModel.context)
        }
    }
}
