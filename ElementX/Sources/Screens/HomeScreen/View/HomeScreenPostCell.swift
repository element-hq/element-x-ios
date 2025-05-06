//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Kingfisher

struct HomeScreenPostCell: View {
    let post: HomeScreenPost
    let mediaProvider: MediaProviderProtocol?
    let postMediaUrl: String?
    let availableLinkPreview: ZLinkPreview?
    let showThreadLine: Bool
    let onPostTapped: () -> Void
    let onOpenArweaveLink: () -> Void
    let onMeowTapped: (Int) -> Void
    
    var body: some View {
        HStack(alignment: .top) {
            if showThreadLine {
                VStack(alignment: .leading, spacing: 0) {
                    // Sender image
                    LoadableAvatarImage(url: post.senderInfo.avatarURL,
                                        name: nil,
                                        contentID: post.senderInfo.userID,
                                        avatarSize: .user(on: .home),
                                        mediaProvider: mediaProvider)
                    
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
                                    mediaProvider: mediaProvider)
            }
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text(post.attributedSenderHeaderText)
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
                if post.attributedPostText != nil {
                    Text(post.attributedPostText!)
                        .font(.zero.bodyMD)
                        .foregroundStyle(.compound.textPrimary)
                        .padding(.vertical, 8)
                }
                
                if let linkPreview = availableLinkPreview {
                    VStack(spacing: 0) {
                        if let thumbnail = linkPreview.thumbnail,
                           let thumbnailURL = linkPreview.thumbnailURL {
                            KFAnimatedImage(thumbnailURL)
                                .placeholder {
                                    Image(systemName: "link")
                                }
                                .aspectRatio(thumbnail.aspectRatio, contentMode: .fit)
                                .cornerRadius(4, corners: .allCorners)
                        }
                        
                        HStack(alignment: .center) {
                            if linkPreview.thumbnail == nil {
                                Image(systemName: "link")
                                    .resizable()
                                    .frame(width: 24, height: 24)
                                    .aspectRatio(contentMode: .fit)
                                    .cornerRadius(4, corners: .allCorners)
                            }
                            VStack(alignment: .leading) {
                                if let title = linkPreview.title {
                                    Text(title)
                                        .font(.zero.bodyMDSemibold)
                                        .foregroundColor(.compound.textPrimary)
                                        .lineLimit(1)
                                }
                                
                                Text(linkPreview.url)
                                    .font(.zero.bodyMD)
                                    .foregroundColor(.compound.textSecondary)
                                    .lineLimit(1)
                            }
                            .padding(.horizontal, 4)
                        }
                    }
                    .padding(.vertical, 4)
                }
                
                if post.mediaInfo != nil {
                    KFAnimatedImage(URL(string: postMediaUrl ?? ""))
                        .placeholder {
                            ProgressView()
                        }
                        .aspectRatio(post.mediaInfo!.aspectRatio, contentMode: .fit)
                        .cornerRadius(4, corners: .allCorners)
                }
                
                HStack {
                    HomeScreenPostFooterItem(icon: Asset.Images.postCommentIcon,
                                             count: post.repliesCount,
                                             highlightColor: false,
                                             action: {
                        onPostTapped()
                    })
                    
                    HomeScreenPostMeowButton(count: post.meowCount,
                                             highlightColor: post.isMeowedByMe,
                                             isEnabled: !post.isMyPost,
                                             onMeowTouchEnded: { count in
                        onMeowTapped(count)
                    })
                    .padding(.horizontal, 32)
                    
                    Spacer()
                    
                    HomeScreenPostFooterItem(icon: Asset.Images.postArweaveIcon,
                                             count: "",
                                             highlightColor: false,
                                             action: {
                        onOpenArweaveLink()
                    })
                }
            }.padding(.leading, 8)
        }
    }
}
