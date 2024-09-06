//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Compound
import SwiftUI

extension View {
    func progressCursor<CursorView: View>(progress: CGFloat,
                                          @ViewBuilder cursorView: @escaping () -> CursorView) -> some View {
        modifier(ProgressCursorModifier(progress: progress,
                                        cursorView: cursorView))
    }
}

private struct ProgressCursorModifier<CursorView: View>: ViewModifier {
    let progress: CGFloat
    @ViewBuilder var cursorView: () -> CursorView
    
    func body(content: Content) -> some View {
        GeometryReader { geometry in
            content
                .overlay(alignment: .leading) {
                    cursorView()
                        .offset(CGSize(width: progress * geometry.size.width, height: 0.0))
                        .frame(height: geometry.size.height)
                }
        }
    }
}
