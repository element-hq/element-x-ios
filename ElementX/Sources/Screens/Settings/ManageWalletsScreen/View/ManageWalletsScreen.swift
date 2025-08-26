//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ManageWalletsScreen: View {
    @ObservedObject var context: ManageWalletsViewModel.Context
    
    var body: some View {
        Form {
            Section("1 Self-Custody Wallet".uppercased()) {
                ZeroListRow(kind: .custom({
                    selfCustodyWallets
                }))
                
                ZeroListRow(kind: .custom({
                    addWalletButton
                }))
            }
            Section("Zero Wallet".uppercased()) {
                ZeroListRow(kind: .custom({
                    zeroWallets
                }))
            }
        }
        .zeroList()
        .navigationTitle("Wallets")
        .navigationBarTitleDisplayMode(.inline)
    }
    
    @ViewBuilder
    private var selfCustodyWallets : some View {
        WalletsListView(wallets: context.viewState.selfCustodyWallets,
                        isSelfCustodyWalletsList: true,
                        onWalletAddressTap: { wallet in
            context.send(viewAction: .onWalletSelected(wallet))
        },
                        onRemoveWalletAddress: { wallet in  })
    }
    
    @ViewBuilder
    private var zeroWallets : some View {
        WalletsListView(wallets: context.viewState.zeroWallets,
                        isSelfCustodyWalletsList: false,
                        onWalletAddressTap: { wallet in
            context.send(viewAction: .onWalletSelected(wallet))
        },
                        onRemoveWalletAddress: { wallet in  })
    }
    
    @ViewBuilder
    private var addWalletButton : some View {
        Button {
            
        } label: {
            HStack {
                CompoundIcon(\.plus)
                    .foregroundStyle(.zero.bgAccentRest)
                
                Text("Add Wallet")
                    .font(.zero.bodyLG)
                    .foregroundStyle(.zero.bgAccentRest)
            }
            .padding(16)
        }
    }
}

private struct WalletsListView: View {
    let wallets: [ZeroWallet]
    let isSelfCustodyWalletsList: Bool
    let onWalletAddressTap: (ZeroWallet) -> Void
    let onRemoveWalletAddress: (ZeroWallet) -> Void
    
    var body: some View {
        if wallets.isEmpty {
            HStack {
                CompoundIcon(\.infoSolid)
                    .foregroundStyle(.compound.textSecondary)
                
                Text("No wallets found")
                    .font(.zero.bodyLG)
                    .foregroundStyle(.compound.textSecondary)
            }
            .padding(16)
        } else {
            LazyVStack(spacing: 0) {
                ForEach(wallets) { wallet in
                    WalletCell(wallet: wallet,
                               showDeleteWalletButton: isSelfCustodyWalletsList,
                               onWalletAddressTap: { onWalletAddressTap(wallet) },
                               onRemoveWalletAddress: { onRemoveWalletAddress(wallet) })
                }
            }
        }
    }
}

private struct WalletCell: View {
    let wallet: ZeroWallet
    let showDeleteWalletButton: Bool
    let onWalletAddressTap: () -> Void
    let onRemoveWalletAddress: () -> Void
    
    var body: some View {
        if let walletAddress = displayFormattedAddress(wallet.address) {
            Button {
                onWalletAddressTap()
            } label: {
                HStack(alignment: .center) {
                    Text(walletAddress)
                        .font(.zero.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                    
                    Spacer()
                    
                    if showDeleteWalletButton {
                        Button {
                            onRemoveWalletAddress()
                        } label: {
                            CompoundIcon(\.close)
                        }
                    }
                }
                .padding(16)
            }
        } else {
            EmptyView()
        }
    }
}
