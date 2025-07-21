//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import Kingfisher

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
                    HomeWalletTabContentCell(content: content, selectedWalletTab: selectedWalletTab, mediaProvider: context.mediaProvider) {}
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
                    mediaProvider: context.mediaProvider,
                    onTap: { _ in }
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
                    mediaProvider: context.mediaProvider,
                    onTap: { content in
                        context.send(viewAction: .viewTransactionDetails(content))
                    }
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
                    mediaProvider: context.mediaProvider,
                    onTap: { _ in }
                )
            }
        }
    }
    
    @ViewBuilder
    fileprivate func walletTabContentView(
        tabContent: WalletTabContent,
        selectedTab: HomeWalletTab,
        mediaProvider: MediaProviderProtocol?,
        onTap: @escaping (HomeScreenWalletContent) -> Void
    ) -> some View {
        if tabContent.items.isEmpty {
            HomeContentEmptyView(message: tabContent.emptyMessage)
        } else {
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(tabContent.items) { content in
                    HomeWalletTabContentCell(content: content,
                                             selectedWalletTab: selectedTab,
                                             mediaProvider: mediaProvider,
                                             onTap: { onTap(content) })
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

struct HomeWalletTabContentCell : View {
    let content: HomeScreenWalletContent
    let selectedWalletTab: HomeWalletTab
    let mediaProvider: MediaProviderProtocol?
    let onTap: () -> Void
    
    var body: some View {
        Button {
            onTap()
        } label: {
            VStack(alignment: .leading) {
                //header
                if let header = content.header {
                    Text(header)
                        .font(.zero.bodySM)
                        .foregroundColor(.compound.textSecondary)
                }
                
                HStack {
                    WalletTokenImage(url: content.icon)
                    
                    VStack(alignment: .leading) {
                        if let transactionAction = content.transactionAction {
                            HStack(spacing: 2) {
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
                            .foregroundColor(.compound.textPrimary)
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
                    
                    if content.transactionAction != nil {
                        CompoundIcon(\.chevronRight, size: .small, relativeTo: .zero.bodyLG)
                            .foregroundStyle(.compound.textSecondary)
                    }
                }
            }
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct WalletTokenImage: View {
    let url: String?
    var size: CGFloat = 44
    
    private var imageURL: URL? {
        guard let urlString = url else { return nil }
        return URL(string: urlString)
    }
    
    var body: some View {
        KFImage(imageURL)
            .placeholder {
                PlaceholderAvatarImage(name: "", contentID: "", onTap: {})
                    .background(Color.compound.bgCanvasDefault)
                    .clipShape(Circle())
                    .frame(width: size, height: size)
            }
            .fade(duration: 0.3)
            .frame(width: size, height: size)
            .clipShape(Circle())
    }
}
