//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct HomeWalletTabsContentView : View {
    @ObservedObject var context: HomeScreenViewModel.Context
    let selectedWalletTab: HomeWalletTab
    
    var body: some View {
        switch context.viewState.postListMode {
        case .skeletons:
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(context.viewState.visiblePosts) { _ in
                    HomeWalletTabContentCell(mediaProvider: context.mediaProvider)
                        .redacted(reason: .placeholder)
                        .shimmer()
                }
            }
            .disabled(true)
        case .empty:
            let msg = switch selectedWalletTab {
            case .account: "No accounts"
            case .token: "No tokens"
            case .transaction: "No transactions"
            }
            HomeContentEmptyView(message: msg)
        case .posts:
            LazyVStack(alignment: .leading, spacing: 0) {
                ForEach(context.viewState.visiblePosts, id: \.id) { _ in
                    HomeWalletTabContentCell(mediaProvider: context.mediaProvider)
                        .padding(.vertical, 12)
                }
                
                HomeTabBottomSpace()
            }
        }
    }
}

private struct HomeWalletTabContentCell : View {
    let mediaProvider: MediaProviderProtocol?
    
    var showHeader: Bool = false
    
    var body: some View {
        VStack(alignment: .leading) {
            //header
            if showHeader {
                Text("Yesterday")
                    .font(.zero.bodySM)
                    .foregroundColor(.compound.textSecondary)
            }
            
            HStack {
                LoadableAvatarImage(url: URL.dummayURL,
                                    name: UUID().uuidString,
                                    contentID: UUID().uuidString,
                                    avatarSize: .user(on: .roomDetails),
                                    mediaProvider: mediaProvider,
                                    onTap: { _ in }
                )
                
                VStack(alignment: .leading) {
//                    HStack {
//                        Text("Received from")
//                            .font(.zero.bodySM)
//                            .foregroundColor(.compound.textSecondary)
//                            .lineLimit(1)
//                            .truncationMode(.tail)
//                        
//                        Text("0://nathan")
//                            .font(.zero.bodySM)
//                            .foregroundColor(.compound.textSecondary)
//                            .lineLimit(1)
//                            .truncationMode(.tail)
//                        
//                        Text("ACTIVE")
//                            .font(.zero.bodySM)
//                            .foregroundColor(.zero.bgAccentRest)
//                    }
                    
                    Text("Wilder World")
                        .font(.zero.bodyLG)
                        .foregroundColor(.compound.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.vertical, 1)
                    
                    Text("24,300.25 WILD")
                        .font(.zero.bodySM)
                        .foregroundColor(.compound.textSecondary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
                
                Spacer()
                
                VStack(alignment: .trailing) {
//                    Text("24,300.25 WILD")
//                        .font(.zero.bodySM)
//                        .foregroundColor(.compound.textSecondary)
//                        .lineLimit(1)
//                        .truncationMode(.tail)
                    
                    Text("$20,002.12")
                        .font(.zero.bodyLG)
                        .foregroundColor(.compound.textPrimary)
                        .lineLimit(1)
                        .truncationMode(.tail)
                        .padding(.vertical, 1)
                    
                    Text("+3.12%")
                        .font(.zero.bodySM)
                        .foregroundColor(.zero.bgAccentRest)
                        .lineLimit(1)
                        .truncationMode(.tail)
                }
            }
            .padding(.leading, 4)
        }
    }
}
