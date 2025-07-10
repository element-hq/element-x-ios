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
    let onMediaTapped: (String) -> Void
    
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
                Spacer()
            }
            .frame(height: referenceHeight)
            .contentShape(Rectangle())
            .onTapGesture {
                onPostTapped()
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
                
                if let mediaInfo = post.mediaInfo {
                    HomePostMediaPreview(mediaInfo: mediaInfo, mediaUrlString: postMediaUrl) {
                        onMediaTapped(mediaInfo.id)
                    }
                }
                
                HStack {
                    HomeScreenPostFooterItem(icon: Asset.Images.postCommentIcon,
                                             count: post.repliesCount,
                                             highlightColor: false,
                                             action: {
                        onPostTapped()
                    })
                    
                    Spacer()
                    
                    HomeScreenPostMeowButton(count: post.meowCount,
                                             highlightColor: post.isMeowedByMe,
                                             isEnabled: !post.isMyPost,
                                             onMeowTouchEnded: { count in
                        onMeowTapped(count)
                    })
                    
                    Spacer()
                    
                    HomeScreenPostFooterItem(icon: Asset.Images.postArweaveIcon,
                                             count: "",
                                             highlightColor: false,
                                             action: {
                        onOpenArweaveLink()
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
                        .fade(duration: 0.3)
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

struct HomePostMediaPreview: View {
    let mediaInfo: HomeScreenPostMediaInfo
    let mediaUrlString: String?
    let onMediaTapped: () -> Void
    
    @State private var didFail = false
    
    private var mediaURL: URL? {
        guard let mediaUrlString else { return nil }
        return URL(string: mediaUrlString)
    }
    
    var body: some View {
        Group {
            if mediaInfo.isVideo {
                videoView
            } else {
                imageView
            }
        }
    }
    
    @ViewBuilder
    private var videoView: some View {
        if let mediaURL {
            VideoPlayerView(videoURL: mediaURL)
                .frame(height: 300)
                .cornerRadius(4)
                .onLongPressGesture {
                    onMediaTapped()
                }
        } else {
            ZStack {
                ProgressView()
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .cornerRadius(4)
        }
    }
    
    @ViewBuilder
    private var imageView: some View {
        if didFail {
            ZStack {
                Image(systemName: "exclamationmark.triangle")
                    .resizable()
                    .frame(width: 80, height: 70)
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .cornerRadius(4)
        } else if let mediaURL {
            KFAnimatedImage(mediaURL)
                .setProcessor(DownsamplingImageProcessor(size: CGSize(width: 300, height: 300)))
                .scaleFactor(UIScreen.main.scale)
                .placeholder { ProgressView() }
                .retry(maxCount: 2, interval: .seconds(2))
                .onFailure { error in
                    MXLog.error("Failed to load feed media image: \(error)")
                    didFail = true
                }
                .fade(duration: 0.3)
                .aspectRatio(mediaInfo.aspectRatio, contentMode: .fit)
                .cornerRadius(4)
                .onTapGesture {
                    onMediaTapped()
                }
        } else {
            ZStack {
                ProgressView()
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .cornerRadius(4)
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
