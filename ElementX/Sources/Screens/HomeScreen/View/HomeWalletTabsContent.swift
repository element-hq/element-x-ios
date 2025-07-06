//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

private struct WalletTabContent {
    let items: [HomeScreenWalletContent]
    let nextPageParams: Any?
    let emptyMessage: String
    let loadMoreAction: () -> Void
}

struct HomeWalletTabsContentView : View {
    @ObservedObject var context: HomeScreenViewModel.Context
    let selectedWalletTab: HomeWalletTab
    
    var body: some View {
        switch context.viewState.walletContentListMode {
        case .skeletons:
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(context.viewState.visibleWalletTokens) { content in
                    HomeWalletTabContentCell(content: content, selectedWalletTab: selectedWalletTab, mediaProvider: context.mediaProvider)
                        .redacted(reason: .placeholder)
                        .shimmer()
                }
            }
            .disabled(true)
        case .content:
            switch selectedWalletTab {
            case .token:
                walletTabContentView(
                    tabContent: WalletTabContent(
                        items: context.viewState.visibleWalletTokens,
                        nextPageParams: context.viewState.walletTokenNextPageParams,
                        emptyMessage: "No tokens",
                        loadMoreAction: { context.send(viewAction: .loadMoreWalletTokens) }
                    ),
                    selectedTab: selectedWalletTab,
                    mediaProvider: context.mediaProvider
                )
                
            case .transaction:
                walletTabContentView(
                    tabContent: WalletTabContent(
                        items: context.viewState.visibleWalletTransactions,
                        nextPageParams: context.viewState.walletTransactionsNextPageParams,
                        emptyMessage: "No transactions",
                        loadMoreAction: { context.send(viewAction: .loadMoreWalletTransactions) }
                    ),
                    selectedTab: selectedWalletTab,
                    mediaProvider: context.mediaProvider
                )
                
            case .account:
                walletTabContentView(
                    tabContent: WalletTabContent(
                        items: context.viewState.visibleWalletNFTs,
                        nextPageParams: context.viewState.walletNFTsNextPageParams,
                        emptyMessage: "No NFTs",
                        loadMoreAction: { context.send(viewAction: .loadMoreWalletNFTs) }
                    ),
                    selectedTab: selectedWalletTab,
                    mediaProvider: context.mediaProvider
                )
            }
        }
    }
    
    @ViewBuilder
    fileprivate func walletTabContentView(
        tabContent: WalletTabContent,
        selectedTab: HomeWalletTab,
        mediaProvider: MediaProviderProtocol?
    ) -> some View {
        if tabContent.items.isEmpty {
            HomeContentEmptyView(message: tabContent.emptyMessage)
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(tabContent.items) { content in
                    HomeWalletTabContentCell(content: content, selectedWalletTab: selectedTab, mediaProvider: mediaProvider)
                        .padding(.vertical, 12)
                }
                
                if tabContent.nextPageParams != nil {
                    ProgressView()
                        .padding()
                        .onAppear {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
                                tabContent.loadMoreAction()
                            }
                        }
                } else {
                    HomeTabBottomSpace()
                }
            }
        }
    }
}

private struct HomeWalletTabContentCell : View {
    let content: HomeScreenWalletContent
    let selectedWalletTab: HomeWalletTab
    let mediaProvider: MediaProviderProtocol?
    
    var body: some View {
        VStack(alignment: .leading) {
            //header
            if let header = content.header {
                Text(header)
                    .font(.zero.bodySM)
                    .foregroundColor(.compound.textSecondary)
            }
            
            HStack {
                LoadableAvatarImage(url: URL(string: content.icon ?? ""),
                                    name: content.title,
                                    contentID: content.id,
                                    avatarSize: .user(on: .roomDetails),
                                    mediaProvider: mediaProvider,
                                    onTap: { _ in }
                )
                
                VStack(alignment: .leading) {
                    if let transactionAction = content.transactionAction {
                        HStack {
                            Text(transactionAction)
                                .font(.zero.bodySM)
                                .foregroundColor(.compound.textSecondary)
                                .lineLimit(1)
                                .layoutPriority(1)
                            
                            Image(asset: Asset.Images.iconZChain)
                            
                            Text(content.transactionAddress ?? "")
                                .font(.zero.bodySM)
                                .foregroundColor(.compound.textSecondary)
                                .lineLimit(1)
                                .truncationMode(.tail)
                                .padding(.trailing, 8)
                        }
                    }
                    
                    Text(content.title)
                        .font(.zero.bodyLG)
                        .foregroundColor(.compound.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.vertical, 1)
                    
                    if let description = content.description {
                        Text(description)
                            .font(.zero.bodySM)
                            .foregroundColor(.compound.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.middle)
                    }
                }
                .padding(.leading, 4)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    if let actionPreText = content.actionPreText {
                        Text(actionPreText)
                            .font(.zero.bodySM)
                            .foregroundColor(.compound.textSecondary)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                    
                    Text(content.actionText)
                        .font(.zero.bodyLG)
                        .foregroundColor(.zero.bgAccentRest)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.vertical, 1)
                    
                    if let actionPostText = content.actionPostText {
                        Text(actionPostText)
                            .font(.zero.bodySM)
                            .foregroundColor(.zero.bgAccentRest)
                            .lineLimit(1)
                            .truncationMode(.tail)
                    }
                }
            }
        }
    }
}
