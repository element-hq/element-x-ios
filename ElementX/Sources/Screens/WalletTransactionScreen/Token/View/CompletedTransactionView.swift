//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct CompletedTransactionView: View {
    @ObservedObject var context: TransferTokenViewModel.Context
    
    var body: some View {
        VStack {
            if let currentUser = context.viewState.currentUser,
               let recipient = context.viewState.transferRecipient,
               let token = context.viewState.tokenAsset {
                
                Spacer()
                
                VStack {
                    ZStack(alignment: .bottomTrailing) {
                        Circle()
                            .fill(.black)
                            .frame(width: 100, height: 100)
                            .shadow(color: .zero.bgAccentRest.opacity(0.5), radius: 20)
                        
                        WalletTokenImage(url: token.logo, size: 100)
                        
                        Image(asset: Asset.Images.iconZChain)
                            .resizable()
                            .frame(width: 24, height: 24)
                    }
                    .background(
                        Circle()
                            .stroke(.compound.bgCanvasDefaultLevel1, lineWidth: 1)
                    )
                    
                    HStack {
                        Text(context.transferAmount)
                            .font(.compound.headingMDBold)
                            .foregroundStyle(.compound.textPrimary)
                            .shadow(color: .white.opacity(0.5), radius: 4)
                        
                        Text(token.symbol.uppercased())
                            .font(.compound.headingMDBold)
                            .foregroundStyle(.compound.textPrimary)
                    }
                    .padding(.top, 12)
                    
                    Text(ZeroWalletUtil.shared.meowPriceFormatted(tokenAmount: context.transferAmount, refPrice: context.viewState.meowPrice))
                        .font(.compound.bodyLGSemibold)
                        .foregroundStyle(.compound.textSecondary)
                        .padding(.top, 4)
                }
                
                Spacer()
                
                HStack {
                    Spacer()
                    
                    UserInfoView(
                        image: context.viewState.userAvatarURL?.absoluteString,
                        name: currentUser.displayName,
                        address: displayFormattedAddress(currentUser.publicWalletAddress),
                        mediaProvider: context.mediaProvider
                    )
                    
                    Spacer()
                    
                    Image(systemName: "chevron.right.2")
                        .font(.system(size: 14))
                        .foregroundColor(.zero.bgAccentRest)
                        .padding(10)
                        .background(
                            Circle()
                                .stroke(.compound.bgCanvasDefaultLevel1, lineWidth: 1)
                        )
                    
                    Spacer()
                    
                    UserInfoView(
                        image: recipient.profileImage,
                        name: recipient.displayName,
                        address: displayFormattedAddress(recipient.publicAddress),
                        mediaProvider: context.mediaProvider
                    )
                    
                    Spacer()
                }
                .padding(.vertical, 16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .stroke(.compound.bgCanvasDefaultLevel1, lineWidth: 1)
                )
                
                Spacer()
                
                VStack {
                    Image(systemName: "checkmark.circle")
                        .font(.system(size: 32, weight: .semibold))
                        .foregroundColor(.zero.bgAccentRest)
                    
                    Text("Transaction Succeeded")
                        .font(.compound.bodyMDSemibold)
                        .foregroundStyle(.zero.bgAccentRest)
                    
                    Text(currentDateTimeFormatted)
                        .font(.zero.bodySM)
                        .foregroundStyle(.compound.textSecondary)
                    
                    HStack(spacing: 12) {
                        Button(action: { context.send(viewAction: .transactionCompleted) }) {
                            Text("Close")
                                .font(.compound.bodyMDSemibold)
                                .foregroundColor(.black)
                                .padding()
                                .frame(maxWidth: .infinity)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(.zero.bgAccentRest)
                                )
                        }
                        
                        Button(action: {
                            context.send(viewAction: .viewTransaction)
                        }) {
                            Text("View on ZScan")
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
                    .padding(.vertical, 12)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
        .padding()
    }
}

private var currentDateTimeFormatted: String {
    let now = Date()
    let formatter = DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter.string(from: now)
}

private struct UserInfoView: View {
    let image: String?
    let name: String
    let address: String?
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomTrailing) {
                LoadableAvatarImage(url: URL(string: image ?? ""),
                                    name: name,
                                    contentID: nil,
                                    avatarSize: .user(on: .roomDetails),
                                    mediaProvider: mediaProvider)
                
                Image(asset: Asset.Images.iconZChain)
            }
            
            Text(name)
                .font(.compound.bodyMDSemibold)
                .foregroundStyle(.compound.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
            
            if let des = address {
                Text(des)
                    .font(.compound.bodySM)
                    .foregroundStyle(.compound.textSecondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
    }
}
