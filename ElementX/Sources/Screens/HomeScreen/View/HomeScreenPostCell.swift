//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Kingfisher
import AVKit

struct HomeScreenPostCell: View {
    let post: HomeScreenPost
    let mediaProvider: MediaProviderProtocol?
    let postMediaUrl: String?
    let availableLinkPreview: ZLinkPreview?
    let showThreadLine: Bool
    let onPostTapped: () -> Void
    let onOpenArweaveLink: () -> Void
    let onMeowTapped: (Int) -> Void
    let onOpenYoutubeLink: (String) -> Void
    let onOpenUserProfile: (ZPostUserProfile) -> Void
    
    var body: some View {
        HStack(alignment: .top) {
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
                            onOpenUserProfile(postSenderProfile)
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
                        onOpenUserProfile(postSenderProfile)
                    }
                })
            }
            VStack(alignment: .leading) {
                HStack(alignment: .center) {
                    Text(post.attributedSenderHeaderText)
                        .lineLimit(1)
                        .onTapGesture {
                            if let postSenderProfile = post.senderProfile {
                                onOpenUserProfile(postSenderProfile)
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
                if post.attributedPostText != nil {
                    Text(post.attributedPostText!)
                        .font(.zero.bodyMD)
                        .foregroundStyle(.compound.textPrimary)
                        .padding(.vertical, 8)
                }
                
                if let linkPreview = availableLinkPreview {
                    HomePostCellLinkPreview(linkPreview: linkPreview)
                        .padding(.vertical, 4)
                        .onTapGesture {
                            onOpenYoutubeLink(linkPreview.url)
                        }
                }
                
                if let mediaInfo = post.mediaInfo,
                   let url = URL(string: postMediaUrl ?? "") {
                    if mediaInfo.isVideo {
                        VideoPlayerView(videoURL: url)
                            .frame(height: 300)
                            .cornerRadius(4)
                    } else {
                        KFAnimatedImage(url)
                            .placeholder {
                                ProgressView()
                            }
                            .aspectRatio(mediaInfo.aspectRatio, contentMode: .fit)
                            .cornerRadius(4, corners: .allCorners)
                    }
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

struct HomePostCellLinkPreview: View {
    let linkPreview: ZLinkPreview
    
    var body: some View {
        VStack(spacing: 0) {
            if let thumbnail = linkPreview.thumbnail,
               let thumbnailURL = linkPreview.thumbnailURL {
                ZStack {
                    KFAnimatedImage(thumbnailURL)
                        .placeholder {
                            Image(systemName: "link")
                        }
                        .aspectRatio(thumbnail.aspectRatio, contentMode: .fit)
                        .cornerRadius(4, corners: .allCorners)
                    
                    if linkPreview.isAYoutubeVideo {
                        Image(systemName: "play")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .padding()
                            .background(.black)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                            .aspectRatio(contentMode: .fit)
                    }
                }
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
                    
                    let description = linkPreview.isAYoutubeVideo ? linkPreview.youtubeVideoDescription : linkPreview.url
                    Text(description)
                        .font(.zero.bodyMD)
                        .foregroundColor(.compound.textSecondary)
                        .lineLimit(1)
                }
            }
        }
    }
}

struct VideoPlayerView: View {
    let videoURL: URL
    
    var body: some View {
        VideoPlayer(player: AVPlayer(url: videoURL))
        //            .aspectRatio(16/9, contentMode: .fit)
            .onAppear {
                AVPlayer(url: videoURL).play()
            }
    }
}
