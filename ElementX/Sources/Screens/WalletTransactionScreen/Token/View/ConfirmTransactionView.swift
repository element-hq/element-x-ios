//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ConfirmTransactionView: View {
    @ObservedObject var context: TransferTokenViewModel.Context
        
    var body: some View {
        ZStack(alignment: .bottom) {
            VStack(alignment: .leading) {
                if let currentUser = context.viewState.currentUser,
                   let recipient = context.viewState.transferRecipient,
                   let token = context.viewState.tokenAsset {
                    
                    VStack(alignment: .leading) {
                        UserInfoView(preText: "From:",
                                     userName: currentUser.displayName,
                                     userAddress: displayFormattedAddress(currentUser.publicWalletAddress))
                        
                        AssetInfoView(tokenAsset: token, amount: $context.transferAmount, isSenderSideInfo: true, iconUrl: token.logo)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.compound.bgCanvasDefaultLevel1, lineWidth: 1)
                    )
                    
                    VStack(alignment: .leading) {
                        UserInfoView(preText: "Sending To:",
                                     userName: recipient.displayName,
                                     userAddress: displayFormattedAddress(recipient.publicAddress))
                        
                        AssetInfoView(tokenAsset: token, amount: $context.transferAmount, isSenderSideInfo: false, iconUrl: token.logo)
                    }
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(.compound.bgCanvasDefaultLevel1, lineWidth: 1)
                    )
                    .padding(.vertical, 12)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .top)
            .padding()
            
            if context.viewState.canMakeTransaction {
                VStack {
                    Text("Review the above before confirming.\nOnce made, your transaction is irreversible.")
                        .font(.zero.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                        .multilineTextAlignment(.center)
                    
                    SwipeToConfirmButton(onConfirm: {
                        context.send(viewAction: .onTransactionConfirmed)
                    })
                    .padding(.vertical, 12)
                }
                .padding()
            }
        }
        .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
        .ignoresSafeArea(.keyboard)
    }
}

private struct UserInfoView: View {
    let preText: String
    let userName: String
    let userAddress: String?
    
    var body: some View {
        HStack {
            Text(preText)
                .font(.compound.bodySMSemibold)
                .foregroundStyle(.compound.textSecondary)
            
            Text(userName)
                .font(.compound.bodySMSemibold)
                .foregroundStyle(.compound.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            if let address = userAddress {
                Text(address)
                    .font(.compound.bodySMSemibold)
                    .foregroundStyle(.compound.textSecondary)
            }
        }
        .padding(10)
        .background(
            RoundedRectangle(cornerRadius: 12).fill(.compound.bgCanvasDefaultLevel1)
        )
    }
}

private struct AssetInfoView: View {
    let tokenAsset: ZWalletToken
    @Binding var amount: String
    let isSenderSideInfo: Bool
    let iconUrl: String?
    
    @FocusState private var isFocused: Bool
    @State private var balance: String = ""
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                ZStack(alignment: .bottomTrailing) {
                    WalletTokenImage(url: iconUrl, size: 52)
                    
                    Image(asset: Asset.Images.iconZChain)
                }
                .background(
                    Circle().stroke(.compound.bgCanvasDefaultLevel1, lineWidth: 1)
                )
                
                VStack(alignment: .leading) {
                    Text(tokenAsset.name.uppercased())
                        .font(.zero.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                    
                    Text("Z Chain") //default chain for now
                        .font(.zero.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                        .padding(.vertical, 1)
                }
            }
            
            if isSenderSideInfo {
                HStack {
                    TextField("0", text: $amount)
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.plain)
                        .submitLabel(.done)
                        .font(.zero.headingSMSemibold)
                        .focused($isFocused)
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                                self.isFocused = true
                            }
                        }
                        .onChange(of: amount) { _, newValue in
                            let enteredAmount = Double(newValue) ?? 0
                            let maxAccount = Double(tokenAsset.amount) ?? 0
                            if enteredAmount > maxAccount {
                                amount = tokenAsset.amount
                            }
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isFocused = false
                                }
                            }
                        }
                    
                    Spacer()
                    
                    if amount != tokenAsset.amount {
                        Button {
                            amount = tokenAsset.amount
                        } label: {
                            Text("Use Max")
                                .font(.zero.bodySMSemibold)
                                .foregroundStyle(.compound.textPrimary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(
                                    RoundedRectangle(cornerRadius: 12).fill(.compound.bgCanvasDefaultLevel1)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.vertical, 12)
                
                HStack {
                    Spacer()
                    
                    Text("Balance: \(amount.isEmpty ? tokenAsset.formattedAmount : balance)")
                        .font(.compound.bodySMSemibold)
                        .foregroundStyle(.compound.textSecondary)
                }
            } else {
                Text(amount.isEmpty ? "0" : amount)
                    .font(.zero.headingSMSemibold)
                    .foregroundStyle(.compound.textPrimary)
                    .padding(.vertical, 12)
            }
        }
        .onChange(of: amount, { _, newValue in
            if let tokenMaxAmmount = Double(tokenAsset.amount),
               let userAmount = Double(newValue) {
                if userAmount > tokenMaxAmmount {
                    amount = tokenAsset.amount
                } else {
                    let diff = tokenMaxAmmount - userAmount
                    balance = String(format: "%.2f", diff)
                }
            } else {
                balance = tokenAsset.formattedAmount
            }
        })
        .padding(8)
    }
}
