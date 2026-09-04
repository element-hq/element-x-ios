//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// Collapses the view to zero height while keeping it in the hierarchy, so that its state is
/// preserved and no `onAppear`/`onDisappear` side effects fire, unlike an `if` statement.
private struct CollapsedModifier: ViewModifier {
    let isCollapsed: Bool
    
    func body(content: Content) -> some View {
        content
            .frame(height: isCollapsed ? 0 : nil, alignment: .top)
            .clipped()
            .allowsHitTesting(!isCollapsed)
            .accessibilityHidden(isCollapsed)
    }
}

extension View {
    func collapsed(_ isCollapsed: Bool) -> some View {
        modifier(CollapsedModifier(isCollapsed: isCollapsed))
    }
}
