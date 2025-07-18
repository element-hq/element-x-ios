//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct SelectTokenAssetView: View {
    @ObservedObject var context: TransferTokenViewModel.Context
    let scrollViewAdapter: ScrollViewAdapter
    
    var body: some View {
        ZStack(alignment: .bottom) {
            content
            
            if let recipient = context.viewState.transferRecipient {
                RecipientView(recipient: recipient)
            }
        }
        .background(Color.zero.bgCanvasDefault.ignoresSafeArea())
        .padding()
    }
    
    var content: some View {
        GeometryReader { geometry in
            ScrollView {
                switch context.viewState.walletTokensListMode {
                case .skeletons:
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(context.viewState.placeholderTokens) { content in
                            HomeWalletTabContentCell(content: content, selectedWalletTab: .token, mediaProvider: context.mediaProvider) {}
                                .redacted(reason: .placeholder)
                                .shimmer()
                        }
                    }
                    .disabled(true)
                case .empty:
                    HomeContentEmptyView(message: "No assets found")
                case .assets(let tokenAssets):
                    LazyVStack(alignment: .leading, spacing: 0) {
                        ForEach(tokenAssets) { content in
                            HomeWalletTabContentCell(content: content, selectedWalletTab: .token, mediaProvider: context.mediaProvider) {
                                context.send(viewAction: .onTokenAssetSelected(content))
                            }
                            .padding(.vertical, 12)
                        }
                        
                        if context.viewState.walletTokenNextPageParams != nil {
                            ProgressView()
                                .padding()
                                .onAppear {
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                        context.send(viewAction: .loadMoreTokenAssets)
                                    }
                                }
                        } else {
                            HomeTabBottomSpace()
                        }
                    }
                }
            }
            .introspect(.scrollView, on: .supportedVersions) { scrollView in
                guard scrollView != scrollViewAdapter.scrollView else { return }
                scrollViewAdapter.scrollView = scrollView
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollIndicators(.hidden)
        }
    }
}

private struct RecipientView: View {
    let recipient: WalletRecipient
    
    var body: some View {
        HStack {
            Text("Sending To:")
                .font(.zero.bodySMSemibold)
                .foregroundStyle(.compound.textSecondary)
            
            Text("\(recipient.name)(\(recipient.primaryZid))")
                .font(.compound.bodySMSemibold)
                .foregroundStyle(.compound.textPrimary)
                .lineLimit(1)
                .truncationMode(.tail)
            
            Spacer()
            
            if let address = displayFormattedAddress(recipient.publicAddress) {
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
