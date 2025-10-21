//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

extension View {
    // MARK: iOS 18
    
    /// Uses the old page style modal so that on iPadOS 18 the presentation detents have no effect.
    @ViewBuilder func backportPresentationSizingPage() -> some View {
        if #available(iOS 18.0, *) {
            presentationSizing(.page)
        } else {
            self
        }
    }
    
    /// A convenience modifier to conditionally apply `.navigationTransition(.zoom(…))` when available.
    @ViewBuilder func backportNavigationTransitionZoom(sourceID: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            navigationTransition(.zoom(sourceID: sourceID, in: namespace))
        } else {
            self
        }
    }
    
    /// A convenience modifier to conditionally apply `.matchedTransitionSource(…)` when available.
    @ViewBuilder func backportMatchedTransitionSource(id: some Hashable, in namespace: Namespace.ID) -> some View {
        if #available(iOS 18.0, *) {
            matchedTransitionSource(id: id, in: namespace)
        } else {
            self
        }
    }
    
    @ViewBuilder func backportAccessibilityHint(_ hint: String, isEnabled: Bool) -> some View {
        if #available(iOS 18, *) {
            accessibilityHint(hint, isEnabled: isEnabled)
        } else {
            self
        }
    }
    
    // MARK: iOS 26
    
    @ViewBuilder func backportTabBarMinimizeBehaviorOnScrollDown() -> some View {
        if #available(iOS 26.0, *) {
            tabBarMinimizeBehavior(.onScrollDown)
        } else {
            self
        }
    }
    
    @ViewBuilder
    func backportSafeAreaBar(edge: VerticalEdge,
                             alignment: HorizontalAlignment = .center,
                             spacing: CGFloat? = nil,
                             content: () -> some View) -> some View {
        if #available(iOS 26.0, *) {
            safeAreaBar(edge: edge, alignment: alignment, spacing: spacing, content: content)
        } else {
            safeAreaInset(edge: edge, alignment: alignment, spacing: spacing) { content().background(Color.compound.bgCanvasDefault.ignoresSafeArea()) }
        }
    }
    
    @ViewBuilder func backportScrollEdgeEffectHidden() -> some View {
        if #available(iOS 26, *) {
            scrollEdgeEffectHidden()
        } else {
            self
        }
    }
}

extension ToolbarContent {
    @ToolbarContentBuilder func backportSharedBackgroundVisibility(_ visibility: Visibility) -> some ToolbarContent {
        if #available(iOS 26.0, *) {
            sharedBackgroundVisibility(visibility)
        } else {
            self
        }
    }
}
