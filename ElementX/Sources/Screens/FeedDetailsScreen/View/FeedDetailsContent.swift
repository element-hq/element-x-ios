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
    let isRefreshable: Bool
    let scrollViewAdapter: ScrollViewAdapter
    
    var body: some View {
        feedDetails
    }
    
    private var feedDetails: some View {
        VStack {
            isRefreshable
                    ? AnyView(actualContent.refreshable { context.send(viewAction: .forceRefreshFeed) })
                    : AnyView(actualContent)
            
            //Add post reply content
            addPostReplyView
        }

    }
    
    private var actualContent: some View {
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
    
    private var addPostReplyView: some View {
        HStack {
            LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                name: nil,
                                contentID: context.viewState.userID,
                                avatarSize: .user(on: .home),
                                mediaProvider: context.mediaProvider)
            
            // TODO: make textfield multi-line
            TextField(text: $context.myPostReply) {
                Text("Post your reply").foregroundColor(.compound.textSecondary)
            }
            .textFieldStyle(.element())
            .disableAutocorrection(true)
            .autocapitalization(.none)
            
            Button {
                context.send(viewAction: .postReply)
            } label: {
                CompoundIcon(\.sendSolid)
                    .scaledPadding(6, relativeTo: .title)
                    .foregroundColor(context.myPostReply.isEmpty ? .compound.iconDisabled : .zero.iconAccentTertiary)
                    .background {
                        Circle()
                            .foregroundColor(context.myPostReply.isEmpty ? .clear : Asset.Colors.zeroDarkGrey.swiftUIColor)
                    }
                    .scaledPadding(4, relativeTo: .compound.headingLG)
            }
            .disabled(context.myPostReply.isEmpty)
        }
        .padding()
    }
}

struct PostRepliesList: View {
    @ObservedObject var context: FeedDetailsScreenViewModel.Context
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        ForEach(Array(context.viewState.visibleReplies.enumerated()), id: \.element.id) { index, post in
            let nextPost = index < context.viewState.visibleReplies.count - 1 ? context.viewState.visibleReplies[index + 1] : nil
            let showThreadLine = nextPost?.senderInfo.userID == post.senderInfo.userID

            VStack(alignment: .leading) {
                HomeScreenPostCell(post: post, mediaProvider: context.mediaProvider, showThreadLine: showThreadLine,
                                   onPostTapped: {
                    context.send(viewAction: .replyTapped(post))
                },
                                   onOpenArweaveLink: {
                    context.send(viewAction: .openArweaveLink(post))
                },
                                   onMeowTapped: { count in
                    context.send(viewAction: .meowTapped(post.id, amount: count, isPostAReply: true))
                })
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                Divider()
            }
            .onTapGesture {
                context.send(viewAction: .replyTapped(post))
            }
        }
    }
}

struct FeedDetailsSection: View {
    let post: HomeScreenPost
    let context: FeedDetailsScreenViewModel.Context
    let shouldNavigateToDetails: Bool
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                //sender image
                LoadableAvatarImage(url: post.senderInfo.avatarURL,
                                    name: nil,
                                    contentID: post.senderInfo.userID,
                                    avatarSize: .user(on: .home),
                                    mediaProvider: context.mediaProvider)
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        Text(post.senderInfo.displayName ?? "")
                            .font(.compound.bodySMSemibold)
                            .lineLimit(1)
                        
                        if post.worldPrimaryZId != nil && !post.isPostInOwnFeed {
                            Spacer()
                            Text("\(ZeroContants.ZERO_CHANNEL_PREFIX)\(post.worldPrimaryZId!)")
                                .font(.zero.bodyMD)
                                .foregroundStyle(.compound.textSecondary)
                                .lineLimit(1)
                                .padding(.leading, 6)
                        }
                    }
                    if post.senderPrimaryZId != nil {
                        Text("\(ZeroContants.ZERO_CHANNEL_PREFIX)\(post.senderPrimaryZId!)")
                            .font(.zero.bodyMD)
                            .foregroundStyle(.compound.textSecondary)
                            .lineLimit(1)
                    }
                }.padding(.leading, 8)
            }
            if post.attributedPostText != nil {
                Text(post.attributedPostText!)
                    .font(.zero.bodyLG)
                    .foregroundStyle(.compound.textPrimary)
                    .padding(.vertical, 12)
            }
            
            Text(post.postDateTime)
                .font(.zero.bodyMD)
                .foregroundStyle(.compound.textSecondary)
                .lineLimit(1)
            
            HStack {
                HomeScreenPostFooterItem(icon: Asset.Images.postCommentIcon,
                                         count: post.repliesCount,
                                         highlightColor: false,
                                         action: {
                    if shouldNavigateToDetails {
                        context.send(viewAction: .replyTapped(post))
                    }
                })
                
                HomeScreenPostMeowButton(count: post.meowCount,
                                         highlightColor: post.isMeowedByMe,
                                         isEnabled: post.isPostInOwnFeed,
                                         onMeowTouchEnded: { count in
                    context.send(viewAction: .meowTapped(post.id, amount: count, isPostAReply: false))
                })
                .padding(.horizontal, 32)
                
                Spacer()
                
                HomeScreenPostFooterItem(icon: Asset.Images.postArweaveIcon,
                                         count: "",
                                         highlightColor: false,
                                         action: {
                    context.send(viewAction: .openArweaveLink(post))
                })
            }
            .padding(.top, 2)
        }
    }
}
