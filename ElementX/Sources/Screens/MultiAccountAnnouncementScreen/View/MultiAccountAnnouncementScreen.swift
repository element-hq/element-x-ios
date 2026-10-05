//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct MultiAccountAnnouncementScreen: View {
    let context: MultiAccountAnnouncementScreenViewModel.Context
    
    @State private var contentHeight: CGFloat = .zero
    @State private var buttonHeight: CGFloat = .zero
    private let topPadding: CGFloat = 44 // For the navigation bar
    
    var body: some View {
        ElementNavigationStack {
            ScrollView {
                content
                    .readHeight($contentHeight)
            }
            .scrollBounceBehavior(.basedOnSize)
            .backportSafeAreaBar(edge: .bottom, spacing: 0) {
                addAccountButton
                    .readHeight($buttonHeight)
            }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ToolbarButton(role: .close) { context.send(viewAction: .close) }
                }
            }
        }
        .presentationDetents([.height(contentHeight + buttonHeight + topPadding)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.compound.bgCanvasDefault)
    }
    
    private var content: some View {
        TitleAndIcon(title: L10n.screenMultiAccountAnnouncementTitle,
                     subtitle: context.viewState.description,
                     icon: \.userProfileSolid,
                     iconStyle: .defaultSolid)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 16)
            .padding(.bottom, 24)
    }
    
    private var addAccountButton: some View {
        Button {
            context.send(viewAction: .addAccount)
        } label: {
            Label(L10n.screenMultiAccountAnnouncementAction, icon: \.plus)
        }
        .buttonStyle(.compound(.primary))
        .padding(16)
    }
}

// MARK: - Previews

struct MultiAccountAnnouncementScreen_Previews: PreviewProvider, TestablePreview {
    static let viewModel = MultiAccountAnnouncementScreenViewModel()
    
    static var previews: some View {
        MultiAccountAnnouncementScreen(context: viewModel.context)
            .previewDisplayName("Default")
    }
}
