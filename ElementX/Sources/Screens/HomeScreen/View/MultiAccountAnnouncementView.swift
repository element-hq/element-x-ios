//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct MultiAccountAnnouncementView: View {
    let context: HomeScreenViewModel.Context
    
    @State private var navigationBarHeight: CGFloat = .zero
    @State private var contentHeight: CGFloat = .zero
    @State private var buttonHeight: CGFloat = .zero
    
    private var subtitle: AttributedString {
        let boldPlaceholder = "{bold}"
        var subtitle = AttributedString(L10n.screenMultiAccountAnnouncementDescription(boldPlaceholder))
        var boldString = AttributedString("\(L10n.commonSettings) > \(L10n.screenSettingsAddAccount)")
        boldString.bold()
        subtitle.replace(boldPlaceholder, with: boldString)
        return subtitle
    }
    
    var body: some View {
        GeometryReader { geometry in
            ElementNavigationStack {
                ScrollView {
                    content
                        .readHeight($contentHeight)
                }
                .scrollBounceBehavior(.basedOnSize)
                .backportSafeAreaBar(edge: .bottom, spacing: 0) {
                    addAccountButton
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                        .readHeight($buttonHeight)
                }
                .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { navigationBarHeight = $0 }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        ToolbarButton(role: .close) { context.send(viewAction: .dismissMultiAccountAnnouncement) }
                    }
                }
            }
        }
        .presentationDetents([.height(navigationBarHeight + contentHeight + buttonHeight)])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.compound.bgCanvasDefault)
    }
    
    private var content: some View {
        TitleAndIcon(title: L10n.screenMultiAccountAnnouncementTitle,
                     subtitle: subtitle,
                     icon: \.userProfileSolid,
                     iconStyle: .defaultSolid)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
    }
    
    private var addAccountButton: some View {
        Button {
            context.send(viewAction: .addAccount)
        } label: {
            Label(L10n.screenMultiAccountAnnouncementAction, icon: \.plus)
        }
        .buttonStyle(.compound(.primary))
        .padding(.horizontal, 16)
        .padding(.top, 16)
    }
}

// MARK: - Previews

struct MultiAccountAnnouncementView_Previews: PreviewProvider, TestablePreview {
    static let viewModel = HomeScreen_Previews.viewModel(.rooms)
    
    static var previews: some View {
        MultiAccountAnnouncementView(context: viewModel.context)
            .previewDisplayName("Default")
    }
}
