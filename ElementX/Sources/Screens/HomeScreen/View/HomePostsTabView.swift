//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum HomePostsTab: CaseIterable {
    case following
    case all
}

struct HomePostsTabView: View {
    @State private var selectedTab: HomePostsTab = .following
    let onTabSelected: (HomePostsTab) -> Void
    
    private let tabs = [
        (title: "Following", tab: HomePostsTab.following),
        (title: "All", tab: HomePostsTab.all)
    ]
    
//    init(@ViewBuilder tabContent: @escaping (HomePostsTab) -> Content,
//         onTabSelected: @escaping (HomePostsTab) -> Void) {
//        self.tabContent = tabContent
//        self.onTabSelected = onTabSelected
//        
//        let appearance = UITabBarAppearance()
//        appearance.configureWithTransparentBackground()
//        appearance.backgroundEffect = UIBlurEffect(style: .regular)
//        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.15) // Tint color
//        
//        UITabBar.appearance().standardAppearance = appearance
//        UITabBar.appearance().scrollEdgeAppearance = appearance
//    }
    
    var body: some View {
        HStack {
            ForEach(tabs, id: \.tab) { tabInfo in
                Button(action: {
                    selectedTab = tabInfo.tab
                }) {
                    Text(tabInfo.title)
                        .padding(.vertical, 8)
                        .padding(.horizontal, 16)
                        .foregroundStyle(tabInfo.tab == selectedTab ? .zero.bgAccentRest : .compound.iconSecondary)
                }
            }
        }
        .onChange(of: selectedTab) { _, newTab in
            onTabSelected(newTab)
        }
    }
}
