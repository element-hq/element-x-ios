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
}

struct HomeTabView<Content: View>: View {
    @State private var selectedTab: HomeTab = .chat
    
    let tabContent: (HomeTab) -> Content
    let onTabSelected: (HomeTab) -> Void
    
    private let tabs = [
        (title: "Chat", icon: Asset.Images.homeTabChatIcon, tab: HomeTab.chat),
        (title: "Channels", icon: Asset.Images.homeTabExplorerIcon, tab: HomeTab.channels),
        (title: "Feed", icon: Asset.Images.homeTabFeedIcon, tab: HomeTab.feed),
        (title: "Notifications", icon: Asset.Images.homeTabNotificationsIcon, tab: HomeTab.notifications),
//        (title: "My Feed", icon: Asset.Images.homeTabProfileIcon, tab: HomeTab.myFeed)
    ]
    
    init(@ViewBuilder tabContent: @escaping (HomeTab) -> Content,
         onTabSelected: @escaping (HomeTab) -> Void) {
        self.tabContent = tabContent
        self.onTabSelected = onTabSelected
        
//        let appearance = UITabBarAppearance()
//        appearance.configureWithTransparentBackground()
//        appearance.backgroundEffect = UIBlurEffect(style: .regular)
//        appearance.backgroundColor = UIColor.black.withAlphaComponent(0.15) // Tint color
//        
//        UITabBar.appearance().standardAppearance = appearance
//        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent(selectedTab)
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .background(.zero.bgCanvasDefault)
            
            customTabView
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        
//        TabView(selection: $selectedTab) {
//            ForEach(tabs, id: \.tab) { tabInfo in
//                tabContent(tabInfo.tab)
//                    .background(.zero.bgCanvasDefault)
//                    .tabItem {
//                        Image(asset: tabInfo.icon)
//                            .foregroundStyle(tabInfo.tab == selectedTab ? .zero.bgAccentRest : .compound.iconSecondary)
//                        //Text(tabInfo.title)
//                    }
//                    .tag(tabInfo.tab)
//            }
//        }
//        .accentColor(.zero.bgAccentRest)
//        .onChange(of: selectedTab) { _, newTab in
//            onTabSelected(newTab)
//        }
    }
    
    var customTabView: some View {
        HStack {
            ForEach(tabs, id: \.tab) { tabInfo in
                Button {
                    selectedTab = tabInfo.tab
                    onTabSelected(tabInfo.tab)
                } label: {
                    Image(asset: tabInfo.icon)
                        .resizable()
                        .renderingMode(.template)
                        .frame(width: 24, height: 24)
                        .foregroundStyle(
                            selectedTab == tabInfo.tab
                            ? .zero.bgAccentRest
                            : .compound.iconSecondary
                        )
                    .frame(maxWidth: .infinity)
                }
            }
        }
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 24)
                .fill(.thinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24)
                        .stroke(Color.gray.opacity(0.2), lineWidth: 1)
                )
                .padding(.horizontal)
                .shadow(radius: 5)
        )
    }
}
