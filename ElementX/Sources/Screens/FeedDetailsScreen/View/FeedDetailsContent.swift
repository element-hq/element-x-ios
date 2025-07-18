//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI
import Kingfisher

struct FeedDetailsContent: View {
    @Environment(\.verticalSizeClass) private var verticalSizeClass
    
    @ObservedObject var context: FeedDetailsScreenViewModel.Context
    let isRefreshable: Bool
    let scrollViewAdapter: ScrollViewAdapter
    
    @FocusState private var isPostTextFieldFocused: Bool  // Focus state
    
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
                                   shouldNavigateToDetails: false,
                                   onOpenUserProfile: { profile in
                    context.send(viewAction: .openPostUserProfile(profile))
                })
                .padding(.all, 16)
                
                Divider()
                    .foregroundStyle(.compound.textSecondary)
                
                // Feed Replies Section
                switch context.viewState.repliesListMode {
                case .skeletons:
                    LazyVStack(spacing: 0) {
                        ForEach(context.viewState.visibleReplies) { reply in
                            VStack {
                                FeedDetailsSection(post: reply,
                                                   context: context,
                                                   shouldNavigateToDetails: false,
                                                   onOpenUserProfile: { _ in })
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
        VStack(alignment: .leading) {
            if let mediaUrl = context.feedMedia {
                ZStack(alignment: .topTrailing) {
                    KFImage(mediaUrl)
                        .placeholder {
                            CompoundIcon(\.playSolid)
                        }
                        .resizable()
                        .scaledToFit()
                        .frame(width: 50, height: 50)
                        .background(.black)
                        .cornerRadius(6, corners: .allCorners)
                        .padding(.vertical, 2)
                    
                    Button {
                        context.send(viewAction: .deleteMedia)
                    } label: {
                        CompoundIcon(\.close)
                            .padding(2)
                            .background(.Grey22)
                            .foregroundStyle(.white)
                            .clipShape(Circle())
                            .frame(width: 6, height: 6)
                    }
                }
                .padding(.vertical, 6)
            }
            
            HStack {
                LoadableAvatarImage(url: context.viewState.userAvatarURL,
                                    name: nil,
                                    contentID: context.viewState.userID,
                                    avatarSize: .user(on: .home),
                                    mediaProvider: context.mediaProvider)
                
                TextField("Post your reply", text: $context.myPostReply,  axis: .vertical)
                    .lineLimit(1...5)
                    .focused($isPostTextFieldFocused)
                    .textFieldStyle(.element())
                    .disableAutocorrection(true)
                    .autocapitalization(.none)
                    .onSubmit {
                        context.myPostReply.append("\n")
                        isPostTextFieldFocused = true
                    }
                
                Button {
                    isPostTextFieldFocused = false
                    context.send(viewAction: .attachMedia)
                } label: {
                    CompoundIcon(\.attachment)
                        .scaledPadding(6, relativeTo: .title)
                        .foregroundColor(.zero.iconAccentTertiary)
                        .background {
                            Circle()
                                .foregroundColor(Asset.Colors.zeroDarkGrey.swiftUIColor)
                        }
                        .scaledPadding(4, relativeTo: .compound.headingLG)
                }
                
                Button {
                    isPostTextFieldFocused = false
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
                HomeScreenPostCell(post: post,
                                   mediaProvider: context.mediaProvider,
                                   postMediaUrl: context.viewState.postRepliesMediaInfoMap[post.id]?.url,
                                   availableLinkPreview: context.viewState.postRepliesLinkPreviewsMap[post.id],
                                   showThreadLine: showThreadLine,
                                   actions: PostActions(
                                    onPostTapped: {
                                        context.send(viewAction: .replyTapped(post))
                                    },
                                    onOpenArweaveLink: {
                                        context.send(viewAction: .openArweaveLink(post))
                                    },
                                    onMeowTapped: { count in
                                        context.send(viewAction: .meowTapped(post.id, amount: count, isPostAReply: true))
                                    },
                                    onOpenYoutubeLink: { url in
                                        context.send(viewAction: .openYoutubeLink(url))
                                    },
                                    onOpenUserProfile: { profile in
                                        context.send(viewAction: .openPostUserProfile(profile))
                                    },
                                    onMediaTapped: { mediaId in
                                        context.send(viewAction: .openMediaPreview(mediaId))
                                    },
                                    onReloadMedia: {
                                        
                                    })
                )
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
    
    let onOpenUserProfile: (ZPostUserProfile) -> Void
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack(alignment: .top) {
                //sender image
                LoadableAvatarImage(url: post.senderInfo.avatarURL,
                                    name: nil,
                                    contentID: post.senderInfo.userID,
                                    avatarSize: .user(on: .home),
                                    mediaProvider: context.mediaProvider,
                                    onTap: { _ in
                    if let postSenderProfile = post.senderProfile {
                        onOpenUserProfile(postSenderProfile)
                    }
                })
                VStack(alignment: .leading) {
                    HStack(alignment: .center) {
                        HStack(spacing: 0) {
                            Text(post.senderInfo.displayName ?? "")
                                .font(.compound.bodyMDSemibold)
                                .foregroundStyle(.compound.textPrimary)
                                .lineLimit(1)
                                .onTapGesture {
                                    if let postSenderProfile = post.senderProfile {
                                        onOpenUserProfile(postSenderProfile)
                                    }
                                }
                            
                            let isZeroProSubscriber: Bool = post.senderProfile?.isZeroProSubscriber == true
                            if isZeroProSubscriber {
                                CompoundIcon(\.verified, size: .small, relativeTo: .compound.bodyMDSemibold)
                                    .foregroundStyle(.zero.bgAccentRest)
                                    .padding(.horizontal, 4)
                            }
                        }
                        
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
            
            if let linkPreview = post.urlLinkPreview {
                PostLinkPreview(linkPreview: linkPreview)
                    .padding(.vertical, 4)
                    .onTapGesture {
                        context.send(viewAction: .openYoutubeLink(linkPreview.url))
                    }
            }
            
            if let mediaInfo = post.mediaInfo {
                PostMediaPreview(externalLoading: true,
                                 mediaInfo: mediaInfo,
                                 mediaUrlString: mediaInfo.url,
                                 onMediaTapped: { context.send(viewAction: .openMediaPreview(mediaInfo.id)) },
                                 onReloadMedia: {})
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
                
                Spacer()
                
                HomeScreenPostMeowButton(count: post.meowCount,
                                         highlightColor: post.isMeowedByMe,
                                         isEnabled: post.isPostInOwnFeed,
                                         onMeowTouchEnded: { count in
                    context.send(viewAction: .meowTapped(post.id, amount: count, isPostAReply: false))
                })
                
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
