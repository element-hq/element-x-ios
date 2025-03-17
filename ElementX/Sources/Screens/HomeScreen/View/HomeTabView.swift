//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

enum HomeTab: CaseIterable {
    case chat
    case channels
    case feed
    case notifications
    case myFeed
    
    static func from(index: Int) -> HomeTab {
        return Self.allCases.indices.contains(index) ? Self.allCases[index] : .chat // by-default `chat` tab is selected
    }
}

struct HomeTabView<Content1: View, Content2: View, Content3: View, Content4: View, Content5: View>: View {
    @State private var selectedTab = 0
    
    let chatTabContent: Content1
    let channelTabContent: Content2
    let notificationsTabContent: Content3
    let homeTabContent: Content4
    let myFeedTabContent: Content5
    
    let onTabSelected: (Int, HomeTab) -> Void
    
    private let tabs = [
        (
            title: "Chat",
            icon: Asset.Images.homeTabChatIcon
        ),
        (
            title: "Channels",
            icon: Asset.Images.homeTabExplorerIcon
        ),
        (
            title: "Feed",
            icon: Asset.Images.homeTabFeedIcon
        ),
        (
            title: "Notifications",
            icon: Asset.Images.homeTabNotificationsIcon
        ),
        (
            title: "My Feed",
            icon: Asset.Images.homeTabProfileIcon
        )
    ]
    
    init(@ViewBuilder chatTabContent: () -> Content1,
         @ViewBuilder channelTabContent: () -> Content2,
         @ViewBuilder notificationsTabContent: () -> Content3,
         @ViewBuilder homeTabContent: () -> Content4,
         @ViewBuilder myFeedTabContent: () -> Content5,
         onTabSelected: @escaping (Int, HomeTab) -> Void) {
        self.chatTabContent = chatTabContent()
        self.channelTabContent = channelTabContent()
        self.notificationsTabContent = notificationsTabContent()
        self.homeTabContent = homeTabContent()
        self.myFeedTabContent = myFeedTabContent()
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
                case 3:
                    notificationsTabContent
                case 4:
                    myFeedTabContent
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
                            icon: tabs[index].icon,
                            isSelected: selectedTab == index,
                            index: index
                        )
                    }
                }
            }
            .background(.ultraThickMaterial)
        }
        .onChange(of: selectedTab) { _, newValue in
            self.onTabSelected(newValue, HomeTab.from(index: newValue))
        }
    }
    
    // Tab Button
    private func tabButton(title: String, icon: ImageAsset, isSelected: Bool, index: Int) -> some View {
        Button(action: { selectedTab = index }) {
            VStack {
                Image(asset: icon)
                    .font(.system(size: 18))
                    .foregroundStyle(isSelected ? .zero.bgAccentRest : .compound.textSecondary)
            }
            .frame(maxWidth: .infinity) // Equal width for all buttons
            .padding(.vertical, 10)
        }
    }
}
