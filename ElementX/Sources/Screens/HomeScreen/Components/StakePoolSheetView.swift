//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

private enum StakePoolViewState {
    case details
    case staking
    case unstaking
}

struct StakePoolSheetView : View {
    let selectedPool: SelectedHomeWalletStakePool
    let onStakeAmount: (String) -> Void
    let onUnstakeAmount: (String) -> Void
    
    @State private var state: StakePoolViewState = .details
    
    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            switch state {
            case .details:
                StakePoolDetailsView(selectedPool: selectedPool,
                                     onStakePool: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        state = .staking
                    }
                }, onUnstakePool: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        state = .unstaking
                    }
                })
            case .staking, .unstaking:
                PoolStakeUnstakeView(selectedPool: selectedPool,
                                     state: state,
                                     onBackClick: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        state = .details
                    }
                },
                                     onStakeAmount: { amount in
                    if state == .unstaking {
                        onUnstakeAmount(amount)
                    } else {
                        onStakeAmount(amount)
                    }
                })
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
    }
}

private struct StakePoolDetailsView : View {
    let selectedPool: SelectedHomeWalletStakePool
    let onStakePool: () -> Void
    let onUnstakePool: () -> Void
    
    var body: some View {
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
                    
                    Text(selectedPool.myStakedTokensFormatted)
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
    
    @ViewBuilder
    var unstakeButton: some View {
        Button(action: onUnstakePool) {
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
        Button(action: onStakePool) {
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

private struct PoolStakeUnstakeView : View {
    let selectedPool: SelectedHomeWalletStakePool
    let state: StakePoolViewState
    let onBackClick: () -> Void
    let onStakeAmount: (String) -> Void
    
    @State private var inputAmount: String = ""
    @State private var hasEnteredAValidAmount: Bool = false
    @FocusState private var isInputFocused: Bool
    
    var refAmount: Double {
        if state == .unstaking {
            selectedPool.myStakedTokens
        } else {
            selectedPool.totalAvailableTokenBalance
        }
    }
    
    var body: some View {
        let stakeTokenName = selectedPool.stakeToken?.symbol.uppercased() ?? ""
        let rewardTokenName = selectedPool.rewardToken?.symbol.uppercased() ?? ""
        
        Button {
            onBackClick()
        } label: {
            CompoundIcon(\.arrowLeft)
        }
        .padding(.top, 24)
        
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
        .padding(.top, 24)
        
        HStack {
            VStack(alignment: .leading) {
                let title = switch state {
                case .unstaking:
                    "Unstake Amount"
                default:
                    "Stake Amount"
                }
                Text(title)
                    .font(.zero.bodyLG)
                    .foregroundColor(.compound.textSecondary)
                
                HStack {
                    TextField("0", text: $inputAmount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .submitLabel(.done)
                        .font(.compound.headingLGBold)
                        .focused($isInputFocused)
                        .onAppear {
                            DispatchQueue.main
                                .asyncAfter(deadline: .now() + 0.3) {
                                    self.isInputFocused = true
                                }
                        }
                        .onChange(of: inputAmount) { _, newValue in
                            let enteredAmount = Double(newValue) ?? 0
                            hasEnteredAValidAmount = enteredAmount > 0 && enteredAmount <= refAmount
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isInputFocused = false
                                }
                            }
                        }
                    
                    Spacer()
                    
                    Text(stakeTokenName)
                        .font(.zero.bodyMD)
                        .foregroundStyle(.compound.textPrimary)
                        .padding(8)
                        .background(.compound.bgCanvasDefaultLevel1)
                        .clipShape(
                            RoundedCornerShape(radius: 12, corners: .allCorners)
                        )
                    
                    Button(action: {
                        inputAmount = refAmount.description
                    }) {
                        Text("Max")
                            .font(.compound.bodySMSemibold)
                            .foregroundColor(.zero.bgAccentRest)
                            .padding()
                            .frame(width: 70, height: 35)
                            .background(
                                RoundedRectangle(cornerRadius: 12)
                                    .fill(.zero.bgAccentRest.opacity(0.15))
                                    .stroke(.zero.bgAccentRest)
                            )
                    }
                }
                .padding(.vertical, 12)
                
                HStack {
                    Spacer()
                    
                    HStack(spacing: 0) {
                        let (subTitle, value) = switch state {
                        case .unstaking:
                            (
                                "Staked: ",
                                "\(selectedPool.myStakedTokensFormatted) \(stakeTokenName)"
                            )
                        default:
                            (
                                "Available: ",
                                "\(selectedPool.totalAvailableTokenBalanceFormatted) \(stakeTokenName)"
                            )
                        }
                        Text(subTitle)
                            .font(.zero.bodyMD)
                            .foregroundColor(.compound.textSecondary)
                        Text(value)
                            .font(.zero.bodyMD)
                            .foregroundColor(.compound.textSecondary)
                    }
                }
            }
            
            Spacer()
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.compound.bgCanvasDefaultLevel1, lineWidth: 1)
        )
        .padding(.vertical, 12)
        
        HStack {
            VStack(alignment: .leading, spacing: 12) {
                Text("Lock Duration")
                    .font(.zero.bodyMD)
                    .foregroundColor(.compound.textSecondary)
                
                Text("No Lock")
                    .font(.zero.bodyLG)
                    .foregroundColor(.compound.textPrimary)
            }
            Spacer()
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .stroke(.compound.bgCanvasDefaultLevel1, lineWidth: 1)
        )
        .padding(.vertical, 12)
        
        if hasEnteredAValidAmount {
            SwipeToConfirmButton(onConfirm: {
                onStakeAmount(inputAmount)
            })
            .padding(.vertical, 12)
        }
        
        Spacer()
    }
}
