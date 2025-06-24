//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct SimpleTabButtonsView<Tab: Hashable>: View {
    let tabs: [Tab]
    let selectedTab: Tab
    let tabTitle: (Tab) -> String
    let onTabSelected: (Tab) -> Void
    
    var showDivider: Bool = false
    
    var body: some View {
        ZStack(alignment: .bottomLeading) {
            HStack {
                ForEach(tabs, id: \.self) { tab in
                    Button(action: {
                        onTabSelected(tab)
                    }) {
                        VStack(spacing: 0) {
                            Text(tabTitle(tab))
                                .font(.compound.bodyMDSemibold)
                                .foregroundStyle(tab == selectedTab ? .compound.textPrimary : .compound.textSecondary)
                            
                            Rectangle()
                                .fill(tab == selectedTab ? Color.zero.bgAccentRest : .clear)
                                .frame(width: 90, height: 2)
                                .cornerRadius(1.5)
                                .padding(.top, 8)
                        }
                        .padding(.all, showDivider ? 0 : 8)
                    }
                }
                
                Spacer()
            }
            .frame(maxWidth: .infinity)
            
            if showDivider {
                HorizontalDivider()
            }
        }
    }
}
