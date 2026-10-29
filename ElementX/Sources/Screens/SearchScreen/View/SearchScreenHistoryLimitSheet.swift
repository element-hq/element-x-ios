//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SearchScreenHistoryLimitSheet: View {
    @Environment(\.dismiss) private var dismiss
    
    @State private var navigationBarHeight: CGFloat = .zero
    @State private var contentHeight: CGFloat = .zero
    @State private var buttonHeight: CGFloat = .zero
    @State private var hasBottomSafeAreaInset = true
    
    var body: some View {
        ElementNavigationStack {
            ScrollView {
                content
                    .readHeight($contentHeight)
            }
            .scrollBounceBehavior(.basedOnSize)
            .backportSafeAreaBar(edge: .bottom, spacing: 0) {
                gotItButton
                    .readHeight($buttonHeight)
            }
            .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { navigationBarHeight = $0 }
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    ToolbarButton(role: .close) { dismiss() }
                }
            }
        }
        .onGeometryChange(for: Bool.self) { $0.safeAreaInsets.bottom > 0 } action: { hasBottomSafeAreaInset = $0 }
        .presentationDetents([contentHeight > 0 ? .height(navigationBarHeight + contentHeight + buttonHeight) : .medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.compound.bgCanvasDefault)
    }
    
    private var content: some View {
        TitleAndIcon(title: L10n.screenSearchHistoryLimitTitle,
                     subtitle: L10n.screenSearchHistoryLimitMessage,
                     icon: \.info,
                     iconStyle: .defaultSolid)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
    }
    
    private var gotItButton: some View {
        Button(L10n.actionGotIt) { dismiss() }
            .buttonStyle(.compound(.primary))
            .padding(.horizontal, 16)
            .padding(.top, 16)
            .padding(.bottom, hasBottomSafeAreaInset ? 0 : 16)
    }
}

// MARK: - Previews

struct SearchScreenHistoryLimitSheet_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        SearchScreenHistoryLimitSheet()
    }
}
