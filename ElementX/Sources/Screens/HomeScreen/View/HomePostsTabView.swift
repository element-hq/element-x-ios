//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

enum HomePostsTab: CaseIterable {
    case following
    case all
}

struct HomePostsTabView: View {
    @State var selectedTab: HomePostsTab = .following
    let onTabSelected: (HomePostsTab) -> Void
    
    private let tabs = [
        (title: "Following", tab: HomePostsTab.following),
        (title: "Everything", tab: HomePostsTab.all)
    ]
    
    var body: some View {
        HStack {
            ForEach(tabs, id: \.tab) { tabInfo in
                Button(action: {
                    selectedTab = tabInfo.tab
                    onTabSelected(tabInfo.tab)
                }) {
                    VStack(spacing: 0) {
                        Text(tabInfo.title)
                            .foregroundStyle(tabInfo.tab == selectedTab ? .zero.bgAccentRest : .compound.iconSecondary)
                        
                        Rectangle()
                            .fill(tabInfo.tab == selectedTab ? Color.zero.bgAccentRest : .clear)
                            .frame(width: 90, height: 2)
                            .cornerRadius(1.5)
                            .padding(.top, 8)
                    }
                    .padding(.all, 8)
                }
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
    }
}
