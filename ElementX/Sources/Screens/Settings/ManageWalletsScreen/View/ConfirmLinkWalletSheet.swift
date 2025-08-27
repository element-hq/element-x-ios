//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct ConfirmLinkWalletSheet : View {
    let existingWallet: ZeroWallet?
    let connectedWalletAddress: String
    let onConfirm: (Bool) -> Void
    let onCancel: () -> Void
    
    @State private var enableLoggingIn: Bool = true
    
    private var headerText: String {
        if existingWallet != nil {
            "This wallet is already linked to your ZERO account:"
        } else {
            "Your currently connected wallet has the address:"
        }
    }
    
    private var walletAddress: String {
        if let existingWallet = existingWallet {
            existingWallet.address
        } else {
            connectedWalletAddress
        }
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            VStack(alignment: .leading) {
                HStack {
                    Text("Link Wallet")
                        .font(.compound.headingMDBold)
                        .foregroundStyle(.compound.textPrimary)
                    
                    Spacer()
                    
                    Button {
                        onCancel()
                    } label: {
                        CompoundIcon(\.close)
                    }
                }
                .padding(.top, 16)
                
                Divider()
                
                Text(headerText)
                    .font(.compound.bodyMD)
                    .foregroundStyle(.compound.textSecondary)
                    .padding(.vertical, 4)
                
                Text(walletAddress)
                    .font(.compound.headingSMSemibold)
                    .foregroundStyle(.compound.textPrimary)
                    .padding(.vertical, 0.5)
                
                VStack(alignment: .leading) {
                    if existingWallet != nil {
                        Text("Switch to another wallet to link a new one")
                            .font(.compound.bodyMD)
                            .foregroundStyle(.compound.textSecondary)
                    } else {
                        Text("Do you want to link this wallet with your ZERO account?")
                            .font(.compound.bodyMD)
                            .foregroundStyle(.compound.textSecondary)
                        
                        Toggle("Enable logging into your zero account with this wallet?", isOn: $enableLoggingIn)
                            .font(.compound.bodyLG)
                            .tint(.zero.bgAccentRest)
                    }
                }
                .padding(.vertical, 16)
            }
            
            if existingWallet == nil {
                Spacer()
                
                HStack {
                    Spacer()
                    
                    Button("Cancel", action: {
                        onCancel()
                    })
                    .foregroundStyle(.compound.textCriticalPrimary)
                    .buttonStyle(.bordered)
                    
                    Spacer()
                    
                    Button("Link Wallet", action: {
                        onConfirm(enableLoggingIn)
                    })
                    .disabled(existingWallet != nil)
                    .foregroundStyle(.zero.bgAccentRest)
                    .buttonStyle(.bordered)
                    
                    Spacer()
                }
            }
            
            Spacer()
        }
        .padding(16)
    }
}
