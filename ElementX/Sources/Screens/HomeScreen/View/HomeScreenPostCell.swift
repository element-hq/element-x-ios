//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Compound

struct HomeScreenPostCell: View {
    let post: HomeScreenPost
    
    var mediaProvider: MediaProviderProtocol? = nil
    var postMediaUrl: String? = nil
    var availableLinkPreview: ZLinkPreview? = nil
    var showThreadLine: Bool = false
    var actions: PostActions? = nil
    
    @State private var referenceHeight: CGFloat = .zero
    
    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .center) {
                if showThreadLine {
                    VStack(alignment: .leading, spacing: 0) {
                        // Sender image
                        LoadableAvatarImage(url: post.senderInfo.avatarURL,
                                            name: nil,
                                            contentID: post.senderInfo.userID,
                                            avatarSize: .user(on: .home),
                                            mediaProvider: mediaProvider,
                                            onTap: { _ in
                            if let postSenderProfile = post.senderProfile {
                                actions?.onOpenUserProfile(postSenderProfile)
                            }
                        })
                        
                        if showThreadLine {
                            // Dynamic vertical line
                            GeometryReader { geometry in
                                Rectangle()
                                    .frame(width: 1, height: geometry.size.height)
                                    .foregroundStyle(.compound.textSecondary.opacity(0.5))
                                    .offset(x: 16, y: 8)
                            }
                        }
                    }
                    .frame(width: 42)
                } else {
                    //sender image
                    LoadableAvatarImage(url: post.senderInfo.avatarURL,
                                        name: nil,
                                        contentID: post.senderInfo.userID,
                                        avatarSize: .user(on: .home),
                                        mediaProvider: mediaProvider,
                                        onTap: { _ in
                        if let postSenderProfile = post.senderProfile {
                            actions?.onOpenUserProfile(postSenderProfile)
                        }
                    })
                }
                Spacer()
            }
            .frame(height: referenceHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                actions?.onPostTapped()
            }
            
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    HStack(spacing: 0) {
                        Text(post.senderInfo.displayName ?? "")
                            .font(.compound.bodyMDSemibold)
                            .foregroundStyle(.compound.textPrimary)
                            .lineLimit(1)
                            .onTapGesture {
                                if let postSenderProfile = post.senderProfile {
                                    actions?.onOpenUserProfile(postSenderProfile)
                                }
                            }
                        
                        let isZeroProSubscriber: Bool = post.senderProfile?.isZeroProSubscriber == true
                        if isZeroProSubscriber {
                            CompoundIcon(\.verified, size: .small, relativeTo: .compound.bodyMDSemibold)
                                .foregroundStyle(.zero.bgAccentRest)
                                .padding(.horizontal, 4)
                        }
                        
                        Text("• \(post.postUpdatedAt)")
                            .font(.zero.bodyMD)
                            .foregroundStyle(.compound.textSecondary)
                            .layoutPriority(1)
                            .padding(.horizontal, isZeroProSubscriber ? 0 : 4)
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
                if post.attributedPostText != nil {
                    Text(post.attributedPostText!)
                        .font(.zero.bodyMD)
                        .foregroundStyle(.compound.textPrimary)
                        .padding(.vertical, 8)
                }
                
                if let linkPreview = availableLinkPreview {
                    PostLinkPreview(linkPreview: linkPreview)
                        .padding(.vertical, 4)
                        .onTapGesture {
                            actions?.onOpenYoutubeLink(linkPreview.url)
                        }
                }
                
                if let mediaInfo = post.mediaInfo {
                    PostMediaPreview(mediaInfo: mediaInfo,
                                     mediaUrlString: postMediaUrl,
                                     onMediaTapped: { actions?.onMediaTapped(mediaInfo.id) },
                                     onReloadMedia: { actions?.onReloadMedia() })
                }
                
                HStack {
                    HomeScreenPostFooterItem(icon: Asset.Images.postCommentIcon,
                                             count: post.repliesCount,
                                             highlightColor: false,
                                             action: {
                        actions?.onPostTapped()
                    })
                    
                    Spacer()
                    
                    HomeScreenPostMeowButton(count: post.meowCount,
                                             highlightColor: post.isMeowedByMe,
                                             isEnabled: !post.isMyPost,
                                             onMeowTouchEnded: { count in
                        actions?.onMeowTapped(count)
                    })
                    
                    Spacer()
                    
                    HomeScreenPostFooterItem(icon: Asset.Images.postArweaveIcon,
                                             count: "",
                                             highlightColor: false,
                                             action: {
                        actions?.onOpenArweaveLink()
                    })
                }
            }
            .padding(.leading, 8)
            .background(GeometryReader { geometry in
                Color.clear
                    .preference(key: HeightPreferenceKey.self, value: geometry.size.height)
            })
            .onPreferenceChange(HeightPreferenceKey.self) { height in
                if referenceHeight != height {
                    DispatchQueue.main.async {
                        self.referenceHeight = height
                    }
                }
            }
        }
    }
}

private struct HeightPreferenceKey: PreferenceKey {
    static var defaultValue: CGFloat = .zero
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}
