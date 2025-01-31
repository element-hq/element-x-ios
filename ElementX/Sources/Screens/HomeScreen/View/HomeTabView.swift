//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomeTabView<Content1: View, Content2: View>: View {
    @State private var selectedTab = 0
    
    let firstTabContent: Content1
    let secondTabContent: Content2
    
    private let tabs = [
        (
            title: "Chat",
            icon: Asset.Images.homeTabChatIcon,
            selectedIcon: Asset.Images.homeTabChatFillIcon
        ),
        (
            title: "Feed",
            icon: Asset.Images.homeTabFeedIcon,
            selectedIcon: Asset.Images.homeTabFeedFillIcon
        )
    ]
    
    init(@ViewBuilder firstTabContent: () -> Content1,
         @ViewBuilder secondTabContent: () -> Content2) {
        self.firstTabContent = firstTabContent()
        self.secondTabContent = secondTabContent()
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content View
            Group {
                if selectedTab == 0 { firstTabContent }
                else { secondTabContent }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Custom Tab Bar
            VStack(spacing: 0) {
                Divider()
                HStack(spacing: 0) {
                    ForEach(0..<tabs.count, id: \.self) { index in
                        tabButton(
                            title: tabs[index].title,
                            icon: selectedTab == index ? tabs[index].selectedIcon : tabs[index].icon,
                            isSelected: selectedTab == index,
                            index: index
                        )
                    }
                }
                .background(.black)
            }
        }
    }
    
    // Tab Button
    private func tabButton(title: String, icon: ImageAsset, isSelected: Bool, index: Int) -> some View {
        Button(action: { withAnimation { selectedTab = index } }) {
            VStack {
                Image(asset: icon)
                    .font(.system(size: 18))
            }
            .frame(maxWidth: .infinity) // Equal width for all buttons
            .padding(.vertical, 10)
        }
    }
}
