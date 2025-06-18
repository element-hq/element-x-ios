//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

enum HomeNotificationsTab: CaseIterable {
    case all
    case highlighted
    case muted
}

struct HomeNotificationsTabView: View {
    @State private var selectedTab: HomeNotificationsTab = .all
    let onTabSelected: (HomeNotificationsTab) -> Void
    
    private let tabs = [
        (title: "All", tab: HomeNotificationsTab.all),
        (title: "Highlights", tab: HomeNotificationsTab.highlighted),
        (title: "Muted", tab: HomeNotificationsTab.muted)
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
                            .font(.compound.bodyMDSemibold)
                            .foregroundStyle(tabInfo.tab == selectedTab ? .compound.textPrimary : .compound.textSecondary)
                        
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
