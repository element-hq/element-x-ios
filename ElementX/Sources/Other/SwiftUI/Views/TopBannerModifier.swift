//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A single banner item to be displayed in a `topBanners` overlay.
struct TopBannerItem {
    var banner: AnyView
    var isVisible: Bool
    
    init(_ banner: some View, isVisible: Bool) {
        self.banner = AnyView(banner)
        self.isVisible = isVisible
    }
}

extension View {
    /// Overlays the given banner view at the top edge of this view, using a
    /// slide from the top edge when `isVisible` is toggled.
    func topBanner(_ banner: some View, isVisible: Bool, footer: some View = EmptyView()) -> some View {
        topBanners([TopBannerItem(banner, isVisible: isVisible)], footer: footer)
    }
    
    /// Overlays the given banner views at the top edge of this view. Each banner
    /// slides from the top edge based on its own `isVisible` flag. Later items in
    /// the array are overlayed on top of earlier ones. The footer is shared across
    /// all banners and displayed below the topmost visible banner.
    func topBanners(_ items: [TopBannerItem], footer: some View = EmptyView()) -> some View {
        let anyBannerVisible = items.contains { $0.isVisible }
        return overlay(alignment: .top) {
            ZStack(alignment: .top) {
                // Visible layout
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            if item.isVisible {
                                item.banner
                                    .transition(.move(edge: .top))
                            }
                        }
                    }
                    footer
                        // Banners include a 28 padding to include shadows in their size
                        // so we need to remove 28 if any is visible
                        .padding(.top, anyBannerVisible ? -15 : 13)
                }
                // Hidden layout used for sizing when no banner is visible
                Color.clear
                    .hidden()
                    .allowsHitTesting(false)
            }
            .animation(.elementDefault, value: items.map(\.isVisible))
            .clipped()
        }
    }
}
