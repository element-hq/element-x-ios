//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Compound
import SwiftUI

struct FeedUserProfileDetailsView: View {
    @ObservedObject var context: FeedUserProfileScreenViewModel.Context
    let scrollViewAdapter: ScrollViewAdapter
    
    var body: some View {
        ZStack {
            content
            
            if !context.viewState.shouldShowDirectChatButton {
                FloatingActionButton(onTap: {
                    context.send(viewAction: .newFeed)
                })
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
            }
        }
    }
    
    var content: some View {
        GeometryReader { geometry in
            ScrollView {
                // Feed Details view
                UserProfileDetailsSection(context: context)
                
                Divider()
                    .foregroundStyle(.compound.textSecondary)
                
                // User Feeds Section
                switch context.viewState.userFeedsListMode {
                case .skeletons:
                    LazyVStack(spacing: 0) {
                        ForEach(context.viewState.visibleFeeds) { feed in
                            VStack {
                                HomeScreenPostCell(post: feed,
                                                   mediaProvider: context.mediaProvider,
                                                   postMediaUrl: nil,
                                                   availableLinkPreview: nil,
                                                   showThreadLine: false,
                                                   onPostTapped: {},
                                                   onOpenArweaveLink: {},
                                                   onMeowTapped: { _ in },
                                                   onOpenYoutubeLink: { _ in },
                                                   onOpenUserProfile: { _ in },
                                                   onMediaTapped: { _ in })
                                .padding(.all, 16)
                                Divider()
                            }
                            .redacted(reason: .placeholder)
                            .shimmer()
                        }
                    }
                    .disabled(true)
                case .empty:
                    HomeContentEmptyView(message: "No posts")
                case .feeds:
                    LazyVStack(spacing: 0) {
                        UserFeedsList(context: context)
                        
                        if context.viewState.canLoadMoreFeeds {
                            ProgressView()
                                .padding()
                                .onAppear {
                                    context.send(viewAction: .loadMoreFeedsIfNeeded)
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
            .scrollDisabled(context.viewState.userFeedsListMode == .skeletons)
            .scrollBounceBehavior(context.viewState.userFeedsListMode == .empty ? .basedOnSize : .automatic)
            .animation(.elementDefault, value: context.viewState.userFeedsListMode)
            .animation(.none, value: context.viewState.visibleFeeds)
        }
    }
}

struct UserProfileDetailsSection: View {
    @ObservedObject var context: FeedUserProfileScreenViewModel.Context
    
    var body: some View {
        VStack(spacing: 0) {
            ZStack(alignment: .bottomLeading) {
                zeroBannerImage
                
                HStack {
                    LoadableAvatarImage(url: URL(string: context.viewState.userProfile.profileImage ?? ""),
                                        name: context.viewState.userProfile.firstName,
                                        contentID: context.viewState.userProfile.userId,
                                        avatarSize: .user(on: .dmDetails),
                                        mediaProvider: context.mediaProvider,
                                        onTap: { url in
                        context.send(viewAction: .displayAvatar(url))
                    })
                    
                    Spacer()
                    
                    if context.viewState.shouldShowDirectChatButton {
                        Button {
                            context.send(viewAction: .openDirectChat)
                        } label: {
                            CompoundIcon(\.chat)
                                .tint(.zero.bgAccentRest)
                        }
                        .frame(width: 48, height: 48)
                        .background(Asset.Colors.zeroContentBackgroundColor.swiftUIColor)
                        .clipShape(Circle())
                    }
                }
                .padding(.horizontal, 16)
                .offset(y: 35)
            }
            .padding(.bottom, 35)
            
            HStack(spacing: 0) {
                VStack(alignment: .leading) {
                    Text(context.viewState.userProfile.firstName)
                        .font(.compound.headingMDBold)
                        .foregroundStyle(.compound.textPrimary)
                        .lineLimit(1)
                    
                    if let zid = context.viewState.userProfile.zIdOrPublicAddressDisplayText {
                        Text(zid)
                            .font(.zero.bodyLG)
                            .foregroundStyle(.compound.textSecondary)
                            .lineLimit(1)
                    }
                }
                
                Spacer()
                
                if context.viewState.userFollowStatus != nil, context.viewState.shouldShowFollowButton {
                    followButton
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .padding(.vertical, 8)
            
            if let followersCount = context.viewState.userProfile.followersCount,
               let followingCount = context.viewState.userProfile.followingCount {
                HStack(spacing: 0) {
                    HStack {
                        Text(followingCount)
                            .font(.compound.bodyLGSemibold)
                            .foregroundStyle(.compound.textPrimary)
                        Text("Following")
                            .font(.compound.bodyLG)
                            .foregroundStyle(.compound.textSecondary)
                    }
                    
                    HStack {
                        Text(followersCount)
                            .font(.compound.bodyLGSemibold)
                            .foregroundStyle(.compound.textPrimary)
                        Text("Followers")
                            .font(.compound.bodyLG)
                            .foregroundStyle(.compound.textSecondary)
                    }
                    .padding(.horizontal, 24)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 16)
            }
        }
    }
    
    @ViewBuilder
    private var zeroBannerImage: some View {
        Image(asset: Asset.Images.zeroBackupHeader)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
    }
    
    @ViewBuilder
    private var followButton: some View {
        Button {
            context.send(viewAction: .toggleFollowUser)
        } label: {
            Text(context.viewState.userFollowStatus?.isFollowing == true ? "Unfollow" : "Follow")
                .font(.zero.bodyMDSemibold)
                .foregroundStyle(Asset.Colors.blue11.swiftUIColor)
                .frame(width: 120, height: 48)
                .background(Color(red: 0.99, green: 0.99, blue: 0.99).opacity(0.05))
                .cornerRadius(9999)
                .overlay(
                    RoundedRectangle(cornerRadius: 9999)
                        .inset(by: 0.5)
                        .stroke(.white.opacity(0.25), lineWidth: 1)
                )
        }
    }
}

struct UserFeedsList: View {
    @ObservedObject var context: FeedUserProfileScreenViewModel.Context
    
    var body: some View {
        content
    }
    
    @ViewBuilder
    private var content: some View {
        ForEach(context.viewState.visibleFeeds, id: \.id) { post in
            VStack(alignment: .leading) {
                HomeScreenPostCell(post: post,
                                   mediaProvider: context.mediaProvider,
                                   postMediaUrl: context.viewState.userFeedsMediaInfoMap[post.id]?.url,
                                   availableLinkPreview: context.viewState.userFeedsLinkPreviewsMap[post.id],
                                   showThreadLine: false,
                                   onPostTapped: {
                    context.send(viewAction: .feedTapped(post))
                },
                                   onOpenArweaveLink: {
                    context.send(viewAction: .openArweaveLink(post))
                },
                                   onMeowTapped: { count in
                    context.send(viewAction: .addMeowToPost(postId: post.id, amount: count))
                },
                                   onOpenYoutubeLink: { url in
                    context.send(viewAction: .openYoutubeLink(url))
                },
                                   onOpenUserProfile: { _ in },
                                   onMediaTapped: { mediaId in
                    context.send(viewAction: .openMediaPreview(mediaId))
                }
                )
                .padding(.horizontal, 16)
                .padding(.top, 12)
                .padding(.bottom, 6)
                Divider()
            }
            .onTapGesture {
                context.send(viewAction: .feedTapped(post))
            }
        }
    }
}
