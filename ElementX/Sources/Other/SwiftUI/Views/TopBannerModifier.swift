//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// An individual banner in the vertical stack of a `TopBannerLayer`.
struct TopBannerItem {
    var banner: AnyView
    var isVisible: Bool
    
    init(_ banner: some View, isVisible: Bool) {
        self.banner = AnyView(banner)
        self.isVisible = isVisible
    }
}

/// A Z-axis banner slot displayed in a `topBanners` overlay. Each slot may
/// contain one or more vertically stacked banners, each with its own
/// visibility. The slot's overall visibility is derived from whether any of
/// its vertical banners are visible. Later items in the `topBanners` array
/// are overlayed on top of earlier ones (Z-axis).
struct TopBannerLayer {
    var verticalBanners: [TopBannerItem]
    
    var isVisible: Bool {
        verticalBanners.contains { $0.isVisible }
    }
    
    /// Convenience initialiser for a single-banner slot.
    init(_ banner: some View, isVisible: Bool) {
        verticalBanners = [TopBannerItem(banner, isVisible: isVisible)]
    }
    
    init(verticalBanners: [TopBannerItem]) {
        self.verticalBanners = verticalBanners
    }
}

extension View {
    /// Overlays the given banner view at the top edge of this view, using a
    /// slide from the top edge when `isVisible` is toggled.
    func topBanner(_ banner: some View, isVisible: Bool, footer: some View = EmptyView()) -> some View {
        topBanners([TopBannerLayer(banner, isVisible: isVisible)], footer: footer)
    }
    
    /// Overlays the given Z-axis banner slots at the top edge of this view.
    /// Later items in the array are overlayed on top of earlier ones. Within
    /// each slot, visible vertical banners are stacked in a VStack and slide
    /// in/out from the top edge. The shadow and bottom padding are applied to
    /// the VStack of each slot. The footer is shared and displayed below the
    /// topmost visible slot.
    func topBanners(_ items: [TopBannerLayer], footer: some View = EmptyView()) -> some View {
        let anyBannerVisible = items.contains { $0.isVisible }
        return overlay(alignment: .top) {
            ZStack(alignment: .top) {
                // Visible layout
                VStack(spacing: 0) {
                    ZStack(alignment: .top) {
                        ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                            if item.isVisible {
                                VStack(spacing: 0) {
                                    ForEach(Array(item.verticalBanners.enumerated()), id: \.offset) { _, vBanner in
                                        if vBanner.isVisible {
                                            vBanner.banner
                                                .transition(.move(edge: .top))
                                        }
                                    }
                                }
                                .compositingGroup()
                                .shadow(color: Color(red: 0.11, green: 0.11, blue: 0.13).opacity(0.1), radius: 12, x: 0, y: 4)
                                // To include the shadow in the size
                                .padding(.bottom, 28)
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
            .animation(.elementDefault, value: items.map { $0.verticalBanners.map(\.isVisible) })
            .clipped()
        }
    }
}
