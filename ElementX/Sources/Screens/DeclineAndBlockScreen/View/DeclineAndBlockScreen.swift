//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct DeclineAndBlockScreen: View {
    @Bindable var context: DeclineAndBlockScreenViewModel.Context
    
    var body: some View {
        Form {
            blockUserSection
            reportSection
            if context.shouldReport {
                reportReasonSection
            }
        }
        .compoundList()
        .navigationTitle(L10n.screenDeclineAndBlockTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .animation(.elementDefault, value: context.shouldReport)
        .alert(item: $context.alert)
    }
    
    private var blockUserSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenDeclineAndBlockBlockUserOptionTitle),
                    kind: .toggle($context.shouldBlockUser))
        } footer: {
            Text(L10n.screenDeclineAndBlockBlockUserOptionDescription)
                .compoundListSectionFooter()
        }
    }
    
    private var reportSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.actionReportRoom),
                    kind: .toggle($context.shouldReport))
        } footer: {
            Text(L10n.screenDeclineAndBlockReportUserOptionDescription)
                .compoundListSectionFooter()
        }
    }
    
    private var reportReasonSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenDeclineAndBlockReportUserReasonPlaceholder),
                    kind: .textField(text: $context.reportReason, axis: .vertical))
                .lineLimit(4, reservesSpace: true)
        }
    }
    
    @ToolbarContentBuilder
    private var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button(L10n.actionCancel) {
                context.send(viewAction: .dismiss)
            }
        }
        
        ToolbarItem(placement: .confirmationAction) {
            Button(L10n.actionDecline) {
                context.send(viewAction: .decline)
            }
            .disabled(context.viewState.isDeclineDisabled)
        }
    }
}

// MARK: - Previews

struct DeclineAndBlockScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = DeclineAndBlockScreenViewModel(userID: "@alice:matrix.org",
                                                          roomID: "!room:matrix.org",
                                                          clientProxy: ClientProxyMock(.init()),
                                                          userIndicatorController: UserIndicatorControllerMock())
    
    static var previews: some View {
        NavigationStack {
            DeclineAndBlockScreen(context: viewModel.context)
        }
        .previewDisplayName("Default")
        NavigationStack {
            DeclineAndBlockScreen(context: viewModel.context)
                .onAppear {
                    viewModel.context.shouldReport = true
                }
        }
        .previewDisplayName("Report room selected")
    }
}
