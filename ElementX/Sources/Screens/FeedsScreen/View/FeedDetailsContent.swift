//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct FeedDetailsContent: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @ObservedObject var context: FeedDetailsScreenViewModel.Context
    let scrollViewAdapter: ScrollViewAdapter
    
    var body: some View {
        feedDetails
    }
    
    private var feedDetails: some View {
        GeometryReader { geometry in
            ScrollView {
                // Feed Details view
                FeedDetailsSection(post: context.viewState.bindings.feed,
                                   context: context,
                                   shouldNavigateToDetails: false)
                    .padding(.all, 16)
                
                Divider()
                    .foregroundStyle(.compound.textSecondary)
                
                // Feed Replies Section
                switch context.viewState.repliesListMode {
                case .skeletons:
                    LazyVStack(spacing: 0) {
                        ForEach(context.viewState.visibleReplies) { reply in
                            VStack {
                                FeedDetailsSection(post: reply, context: context, shouldNavigateToDetails: false)
                                    .padding(.all, 16)
                                Divider()
                            }
                            .redacted(reason: .placeholder)
                            .shimmer()
                        }
                    }
                    .disabled(true)
                case .empty:
                    EmptyView()
                case .replies:
                    LazyVStack(spacing: 0) {
                        PostRepliesList(context: context)
                        
                        if context.viewState.canLoadMoreReplies {
                            ProgressView()
                                .padding()
                                .onAppear {
                                    context.send(viewAction: .loadMoreRepliesIfNeeded)
                                }
                        }
                    }
                }
            }
            .introspect(.scrollView, on: .supportedVersions) { scrollView in
                guard scrollView != scrollViewAdapter.scrollView else { return }
                scrollViewAdapter.scrollView = scrollView
            }
            .scrollDismissesKeyboard(.immediately)
            .scrollDisabled(context.viewState.repliesListMode == .skeletons)
            .scrollBounceBehavior(context.viewState.repliesListMode == .empty ? .basedOnSize : .automatic)
            .animation(.elementDefault, value: context.viewState.repliesListMode)
            .animation(.none, value: context.viewState.visibleReplies)
        }
    }
}

struct PostRepliesList: View {
    @ObservedObject var context: FeedDetailsScreenViewModel.Context
    
    var body: some View {
        content
            .padding(.horizontal, 16)
    }
    
    @ViewBuilder
    private var content: some View {
        ForEach(context.viewState.visibleReplies) { post in
            VStack(alignment: .leading) {
                FeedDetailsSection(post: post, context: context, shouldNavigateToDetails: true)
                    .padding(.all, 16)
                Divider()
            }
            .onTapGesture {
                context.send(viewAction: .replyTapped(post))
            }
        }
    }
}

struct FeedDetailsSection: View {
    @Environment(\.dynamicTypeSize) var dynamicTypeSize
    @Environment(\.redactionReasons) private var redactionReasons
    
    let post: HomeScreenPost
    let context: FeedDetailsScreenViewModel.Context
    let shouldNavigateToDetails: Bool
    
    var body: some View {
        HStack(alignment: .top) {
            //sender image
            LoadableAvatarImage(url: post.senderInfo.avatarURL,
                                name: nil,
                                contentID: post.senderInfo.userID,
                                avatarSize: .user(on: .home),
                                mediaProvider: context.mediaProvider)
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text(post.attributedSenderHeaderText)
                        .lineLimit(1)
                    
                    if post.worldPrimaryZId != nil && !post.isPostInOwnFeed {
                        Spacer()
                        Text("0://\(post.worldPrimaryZId!)")
                            .font(.compound.bodyMDSemibold)
                            .foregroundStyle(.compound.textSecondary)
                            .lineLimit(1)
                            .padding(.leading, 6)
                    }
                }
                if post.senderPrimaryZId != nil {
                    Text("0://\(post.senderPrimaryZId!)")
                        .font(.zero.bodyMD)
                        .foregroundStyle(.compound.textSecondary)
                        .lineLimit(1)
                }
                if post.attributedPostText != nil {
                    Text(post.attributedPostText!)
                        .font(.zero.bodyLG)
                        .foregroundStyle(.compound.textPrimary)
                        .padding(.vertical, 12)
                }
                
                HStack {
                    HomeScreenPostFooterItem(icon: Asset.Images.postMeowIcon,
                                             count: post.meowCount,
                                             highlightColor: true,
                                             action: {})
                    
                    HomeScreenPostFooterItem(icon: Asset.Images.postCommentIcon,
                                             count: post.repliesCount,
                                             highlightColor: false,
                                             action: {
                        if shouldNavigateToDetails {
                            context.send(viewAction: .replyTapped(post))
                        }
                    })
                    .padding(.horizontal, 24)
                    
                    Spacer()
                    
                    HomeScreenPostFooterItem(icon: Asset.Images.postArweaveIcon,
                                             count: "",
                                             highlightColor: false,
                                             action: {
                        context.send(viewAction: .openArweaveLink(post))
                    })
                }
            }
        }
    }
}
