//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct UserWalletInfoView: View {
    @ObservedObject var context: ReceiveTransactionViewModel.Context
    
    @State private var qrCodeImage: UIImage?
    @State private var showShareSheet: Bool = false
    
    var body: some View {
        VStack {
            Spacer()
            
            if let user = context.viewState.currentUser, let address = user.publicWalletAddress {
                VStack {
                    Text(user.displayName)
                        .font(.compound.headingSMSemibold)
                        .foregroundStyle(.compound.textPrimary)
                    
                    if let formattedAddress = displayFormattedAddress(address) {
                        Text(formattedAddress)
                            .font(.zero.bodyMD)
                            .foregroundStyle(.compound.textSecondary)
                    }
                    
                    UserWalletQRCode(walletAddress: address, onQRCodeGenerated: { qrCodeImage in
                        self.qrCodeImage = qrCodeImage
                    })
                    .padding(.vertical, 12)
                    
                    Text("Supported Networks")
                        .font(.zero.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                    
                    Image(asset: Asset.Images.iconZChain)
                }
                
                Spacer()
            }
            
            HStack(spacing: 12) {
                CopyButton(onTap : {
                    context.send(viewAction: .copyAddress)
                })
                
                if qrCodeImage != nil {
                    ShareButton(onTap: {
                        showShareSheet = true
                    })
                }
            }
            .padding(.bottom, 16)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
        .padding()
        .sheet(isPresented: $showShareSheet) {
            if let qrImage = qrCodeImage {
                ShareSheet(activityItems: [qrImage])
            }
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let activityItems: [Any]
    
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: activityItems, applicationActivities: nil)
    }
    
    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

struct CopyButton: View {
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Button {
                onTap()
            } label: {
                Image(asset: Asset.Images.iconCopy)
                    .renderingMode(.template)
                    .foregroundStyle(.compound.iconSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.compound.iconSecondary, lineWidth: 1)
            )
            
            Text("Copy")
                .font(.zero.bodySM)
                .foregroundStyle(.compound.iconSecondary)
                .padding(.vertical, 1)
        }
    }
}

struct ShareButton: View {
    let onTap: () -> Void
    
    var body: some View {
        VStack {
            Button {
                onTap()
            } label: {
                CompoundIcon(\.share)
                    .foregroundStyle(.compound.iconSecondary)
            }
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(.compound.iconSecondary, lineWidth: 1)
            )
            
            Text("Share")
                .font(.zero.bodySM)
                .foregroundStyle(.compound.iconSecondary)
                .padding(.vertical, 1)
        }
    }
}
