//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct HomeWalletStakingContent : View {
    let stakingItems: [HomeScreenWalletStakingContent]
    let mediaProvider: MediaProviderProtocol?
    let onTap: (HomeScreenWalletStakingContent) -> Void
    
    var body: some View {
        LazyVStack(alignment: .leading, spacing: 0) {
            // Staking Header
            HStack {
                Text("Pool Name")
                    .font(.compound.bodyMDSemibold)
                    .foregroundStyle(.compound.textSecondary)
                
                Spacer()
                
                Spacer()
                
                Text("TVL")
                    .font(.compound.bodyMDSemibold)
                    .foregroundStyle(.compound.textSecondary)
                
                Spacer()
                
                Text("Your Stake")
                    .font(.compound.bodyMDSemibold)
                    .foregroundStyle(.compound.textSecondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            
            if stakingItems.isEmpty {
                HomeContentEmptyView(message: "No data")
            } else {
                // Staking Listing
                ForEach(stakingItems) { item in
                    WalletStakingContentCell(item: item, mediaProvider: mediaProvider, onTap: {
                        onTap(item)
                    })
                    .padding(.vertical, 12)
                }
                
                HomeTabBottomSpace()
            }
        }
    }
}

struct WalletStakingContentCell : View {
    let item: HomeScreenWalletStakingContent
    let mediaProvider: MediaProviderProtocol?
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    HStack {
                        ZStack(alignment: .bottomTrailing) {
                            WalletTokenImage(url: item.poolIcon)
                            
                            Image(asset: Asset.Images.iconZChain)
                        }
                        
                        Text(item.poolName)
                            .font(.zero.bodyLG)
                            .foregroundColor(.compound.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
//                    Spacer()
                    
                    Spacer()
                    
                    Text(item.totalStakedAmountFormatted)
                        .font(.zero.bodyLG)
                        .foregroundColor(.compound.textPrimary)
                        .layoutPriority(1)
                    
                    Spacer()
                    
                    Text(item.myStateAmountFormatted)
                        .font(.zero.bodyLG)
                        .foregroundColor(.compound.textPrimary)
                        .lineLimit(1)
                        .layoutPriority(1)
                }
            }
        }
    }
}
