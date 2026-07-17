//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

extension View {
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
    
    @ViewBuilder func backportButtonStyleGlass() -> some View {
        if #available(iOS 26, *) {
            buttonStyle(.glass)
        } else {
            self
        }
    }
    
    @ViewBuilder func backportButtonStyleGlassProminent() -> some View {
        if #available(iOS 26, *) {
            // `.glassProminent` breaks our preview tests so we need to disable it when running tests.
            // https://github.com/pointfreeco/swift-snapshot-testing/issues/1029#issuecomment-3366942138
            if ProcessInfo.isRunningUnitTests {
                self
            } else {
                buttonStyle(.glassProminent)
            }
        } else {
            buttonStyle(.borderedProminent)
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
