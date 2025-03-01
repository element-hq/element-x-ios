//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct HomeTabView<Content1: View, Content2: View, Content3: View>: View {
    @State private var selectedTab = 0
    
    let chatTabContent: Content1
    let homeTabContent: Content2
    let channelTabContent: Content3
    let onTabSelected: (Int) -> Void
    
    private let tabs = [
        (
            title: "Chat",
            icon: Asset.Images.homeTabChatIcon,
            selectedIcon: Asset.Images.homeTabChatFillIcon
        ),
        (
            title: "Channels",
            icon: Asset.Images.homeTabExplorerIcon,
            selectedIcon: Asset.Images.homeTabExplorerFillIcon
        ),
        (
            title: "Feed",
            icon: Asset.Images.homeTabFeedIcon,
            selectedIcon: Asset.Images.homeTabFeedFillIcon
        )
    ]
    
    init(@ViewBuilder chatTabContent: () -> Content1,
         @ViewBuilder homeTabContent: () -> Content2,
         @ViewBuilder channelTabContent: () -> Content3,
         onTabSelected: @escaping (Int) -> Void) {
        self.chatTabContent = chatTabContent()
        self.homeTabContent = homeTabContent()
        self.channelTabContent = channelTabContent()
        self.onTabSelected = onTabSelected
    }
    
    var body: some View {
        VStack(spacing: 0) {
            // Content View
            Group {
                switch selectedTab {
                case 1:
                    channelTabContent
                case 2:
                    homeTabContent
                default:
                    chatTabContent
                }
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
            }
            .background(.ultraThickMaterial)
        }
        .onChange(of: selectedTab) { _, newValue in
            self.onTabSelected(newValue)
        }
    }
    
    // Tab Button
    private func tabButton(title: String, icon: ImageAsset, isSelected: Bool, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            VStack {
                Image(asset: icon)
                    .font(.system(size: 18))
            }
            .frame(maxWidth: .infinity) // Equal width for all buttons
            .padding(.vertical, 10)
        }
    }
}
