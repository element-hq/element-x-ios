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
    @Binding var state: StakePoolViewState
    let onStakeAmount: (String) -> Void
    let onUnstakeAmount: (String) -> Void
    let onDismissSheet: () -> Void
    let onClaimStakeRewards: () -> Void
    
    @State private var isUserStakingAmount: Bool = false
    @State private var transactionAmount: String = ""
    
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
                }, onClaimStakeRewards: { onClaimStakeRewards() })
            case .staking, .unstaking:
                PoolStakeUnstakeView(selectedPool: selectedPool,
                                     state: state,
                                     onBackClick: {
                    withAnimation(.easeInOut(duration: 0.3)) {
                        state = .details
                    }
                },
                                     onStakeAmount: { amount in
                    transactionAmount = amount
                    if state == .unstaking {
                        onUnstakeAmount(amount)
                        isUserStakingAmount = false
                    } else {
                        onStakeAmount(amount)
                        isUserStakingAmount = true
                    }
                })
            case .inProgress:
                TransactionInProgressView(
                    color: .zero.bgAccentRest,
                    message: getTransactionInProgressMessage(selectedPool: selectedPool,
                                                             isUserStakingAmount: isUserStakingAmount,
                                                             amount: transactionAmount),
                    subMessage: "Please wait...",
                    backgroundColor: Color.compound.bgCanvasDefault
                )
            case .success, .failure:
                TransactionSuccessOrFailureView(isSuccessful: state == .success,
                                                selectedPool: selectedPool,
                                                hasUserStaked: isUserStakingAmount,
                                                transactionAmount: transactionAmount,
                                                onDismiss: onDismissSheet)
            }
        }
        .padding(.horizontal, 24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.compound.bgCanvasDefault.ignoresSafeArea())
    }
    
    private func getTransactionInProgressMessage(selectedPool: SelectedHomeWalletStakePool,
                                                 isUserStakingAmount: Bool,
                                                 amount: String) -> String {
        let stakeTokenName = selectedPool.stakeToken?.symbol.uppercased() ?? ""
        if isUserStakingAmount {
            return "Staking \(amount) \(stakeTokenName)".trim()
        } else {
            return "Unstaking \(amount) \(stakeTokenName)".trim()
        }
    }
}

private struct StakePoolDetailsView : View {
    let selectedPool: SelectedHomeWalletStakePool
    let onStakePool: () -> Void
    let onUnstakePool: () -> Void
    let onClaimStakeRewards: () -> Void
    
    var body: some View {
        let stakeTokenName = selectedPool.stakeToken?.symbol.uppercased() ?? ""
        let rewardTokenName = selectedPool.rewardToken?.symbol.uppercased() ?? ""
        let rewardTokenBalance = selectedPool.pool.pendingRewards
        let hasUnclaimedRewards = rewardTokenBalance > 0
        
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
                HStack {
                    Text("Claimable Rewards \(rewardTokenName)")
                        .font(.zero.bodyMD)
                        .foregroundColor(.compound.textSecondary)
                    
                    Spacer()
                    
                    if hasUnclaimedRewards {
                        ClaimEarningsButton(
                            text: "Claim Rewards",
                            onTap: { onClaimStakeRewards() }
                        )
                    }
                }
                
                Text(rewardTokenBalance.formatToSuffix())
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

private struct TransactionSuccessOrFailureView : View {
    let isSuccessful: Bool
    let selectedPool: SelectedHomeWalletStakePool
    let hasUserStaked: Bool
    let transactionAmount: String
    let onDismiss: () -> Void
    
    var body: some View {
        let stakeTokenName = selectedPool.stakeToken?.symbol.uppercased() ?? ""
        let rewardTokenName = selectedPool.rewardToken?.symbol.uppercased() ?? ""
        
        HStack {
            Spacer()
            
            Button {
                onDismiss()
            } label: {
                CompoundIcon(\.close)
            }
        }
        .padding(.top, 24)
        
        Spacer()
        
        HStack {
            Spacer()
            VStack {
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
                
                let message: () -> String = {
                    if isSuccessful {
                        if hasUserStaked {
                            "You have successfully staked \(transactionAmount) \(stakeTokenName) without lock.".trim()
                        } else {
                            "You have successfully unstaked \(transactionAmount) \(stakeTokenName), and claimed your pool rewards.".trim()
                        }
                    } else {
                        if hasUserStaked {
                            "Failed to stake \(transactionAmount) \(stakeTokenName) without lock.".trim()
                        } else {
                            "Failed to unstake \(transactionAmount) \(stakeTokenName), and claimed your pool rewards.".trim()
                        }
                    }
                }
                Text(message())
                    .font(.zero.bodyLG)
                    .foregroundStyle(isSuccessful ? .zero.bgAccentRest : .compound.textCriticalPrimary)
                    .padding(.vertical, 12)
                    .multilineTextAlignment(.center)
            }
            Spacer()
        }
        
        Spacer()
    }
}
