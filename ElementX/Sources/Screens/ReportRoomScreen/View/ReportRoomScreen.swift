//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ReportRoomScreen: View {
    @Bindable var context: ReportRoomScreenViewModel.Context
    
    var body: some View {
        Form {
            reasonSection
            leaveRoomSection
        }
        .compoundList()
        .navigationTitle(L10n.screenReportRoomTitle)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar { toolbar }
        .alert(item: $context.alert)
    }
    
    private var reasonSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.screenReportRoomReasonPlaceholder),
                    kind: .textField(text: $context.reason, axis: .vertical))
                .lineLimit(4, reservesSpace: true)
        } footer: {
            Text(L10n.screenReportRoomReasonFooter)
                .compoundListSectionFooter()
        }
    }
    
    private var leaveRoomSection: some View {
        Section {
            ListRow(label: .plain(title: L10n.actionLeaveRoom),
                    kind: .toggle($context.shouldLeaveRoom))
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
            Button(L10n.actionReport) {
                context.send(viewAction: .report)
            }
            .disabled(!context.viewState.canReport)
        }
    }
}

// MARK: - Previews

struct ReportRoomScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = ReportRoomScreenViewModel(roomProxy: JoinedRoomProxyMock(.init()),
                                                     userIndicatorController: UserIndicatorControllerMock())
    static var previews: some View {
        NavigationStack {
            ReportRoomScreen(context: viewModel.context)
        }
    }
}
