//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct StakePoolSheetView : View {
    let selectedPool: SelectedHomeWalletStakePool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            let stakeTokenName = selectedPool.stakeToken?.symbol.uppercased() ?? ""
            let rewardTokenName = selectedPool.rewardToken?.symbol.uppercased() ?? ""
            let rewardTokenBalance = selectedPool.claimableRewardValue
            
            Text("Pool Details")
                .font(.compound.bodyMDSemibold)
                .foregroundStyle(.compound.textSecondary)
            
            HStack {
                HStack {
                    ZStack(alignment: .bottomTrailing) {
                        WalletTokenImage(url: selectedPool.pool.poolIcon)
                        
                        Image(asset: Asset.Images.iconZChain)
                    }
                    
                    VStack(alignment: .leading) {
                        Text(selectedPool.pool.poolName)
                            .font(.zero.bodyLG)
                            .foregroundColor(.compound.textPrimary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                        
                        Text("Reward: \(rewardTokenName)")
                            .font(.zero.bodyMD)
                            .foregroundColor(.compound.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
            .padding(.vertical, 24)
            
            Text("Stake your \(stakeTokenName) to earn \(rewardTokenName) rewards.")
                .font(.zero.bodyLG)
                .foregroundColor(.compound.textSecondary)
            
            HStack {
                VStack(alignment: .leading) {
                    Text("Claimable Rewards \(rewardTokenName)")
                        .font(.zero.bodyMD)
                        .foregroundColor(.compound.textSecondary)
                    
                    Text(rewardTokenBalance)
                        .font(.compound.headingMDBold)
                        .foregroundColor(.compound.textPrimary)
                }
                Spacer()
            }
            .padding(12)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.compound.bgCanvasDefaultLevel1, lineWidth: 1)
            )
            .padding(.vertical, 16)
            
            HStack {
                HStack {
                    VStack(alignment: .leading) {
                        Text("TVL")
                            .font(.zero.bodyMD)
                            .foregroundColor(.compound.textSecondary)
                        
                        Text(selectedPool.pool.totalStakedAmountFormatted)
                            .font(.compound.headingMDBold)
                            .foregroundColor(.compound.textPrimary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.compound.bgCanvasDefaultLevel1, lineWidth: 1)
                )
                
                Spacer()
                Spacer()
                
                HStack {
                    VStack(alignment: .leading) {
                        Text("My Staked \(stakeTokenName)")
                            .font(.zero.bodyMD)
                            .foregroundColor(.compound.textSecondary)
                        
                        Text(selectedPool.myStakedTokens)
                            .font(.compound.headingMDBold)
                            .foregroundColor(.compound.textPrimary)
                    }
                    Spacer()
                }
                .padding(12)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.compound.bgCanvasDefaultLevel1, lineWidth: 1)
                )
            }
            
            HStack {
                stakeButton
                if selectedPool.pool.myStakeAmount > 0 {
                    unstakeButton
                }
            }
            .padding(.vertical, 24)
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
    }
    
    @ViewBuilder
    var unstakeButton: some View {
        Button(action: {
            
        }) {
            Text("Unstake")
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.zero.bgAccentRest)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.zero.bgAccentRest.opacity(0.15))
                        .stroke(.zero.bgAccentRest)
                )
        }
    }
    
    @ViewBuilder
    var stakeButton: some View {
        Button(action: {
            
        }) {
            Text("Stake")
                .font(.compound.bodyMDSemibold)
                .foregroundColor(.black)
                .padding()
                .frame(maxWidth: .infinity)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(.zero.bgAccentRest)
                )
        }
    }
}
