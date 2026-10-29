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
    
    var body: some View {
        GeometryReader { geometry in
            ElementNavigationStack {
                ScrollView {
                    content
                        .readHeight($contentHeight)
                }
                .scrollBounceBehavior(.basedOnSize)
                .backportSafeAreaBar(edge: .bottom, spacing: 0) {
                    gotItButton
                        .padding(.bottom, geometry.safeAreaInsets.bottom > 0 ? 0 : 16)
                        .readHeight($buttonHeight)
                }
                .onGeometryChange(for: CGFloat.self) { $0.safeAreaInsets.top } action: { navigationBarHeight = $0 }
                .toolbar {
                    ToolbarItem(placement: .primaryAction) {
                        ToolbarButton(role: .close) { dismiss() }
                    }
                }
            }
        }
        .presentationDetents([contentHeight > 0 ? .height(navigationBarHeight + contentHeight + buttonHeight) : .medium])
        .presentationDragIndicator(.hidden)
        .presentationBackground(.compound.bgCanvasDefault)
    }
    
    private var content: some View {
        TitleAndIcon(title: UntranslatedL10n.screenSearchHistoryLimitTitle,
                     subtitle: UntranslatedL10n.screenSearchHistoryLimitMessage,
                     icon: \.info,
                     iconStyle: .defaultSolid)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 24)
            .padding(.top, 8)
            .padding(.bottom, 24)
    }
    
    private var gotItButton: some View {
        Button(UntranslatedL10n.actionGotIt) { dismiss() }
            .buttonStyle(.compound(.primary))
            .padding(.horizontal, 16)
            .padding(.top, 16)
    }
}

// MARK: - Previews

struct SearchScreenHistoryLimitSheet_Previews: PreviewProvider, TestablePreview {
    static var previews: some View {
        SearchScreenHistoryLimitSheet()
    }
}
