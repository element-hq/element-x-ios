//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Kingfisher

struct PostMediaPreview: View {
    let mediaInfo: HomeScreenPostMediaInfo
    let mediaUrlString: String?
    let onMediaTapped: () -> Void
    let onReloadMedia: () -> Void
    
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
            PostVideoPlayerView(videoURL: mediaURL)
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
                RefreshButton(onRefresh: { onReloadMedia() })
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .cornerRadius(4)
        } else if let mediaURL {
            let source = KF.ImageResource(downloadURL: mediaURL, cacheKey: mediaInfo.id)
            KFAnimatedImage(source: .network(source))
                .cacheOriginalImage()
                .diskCacheExpiration(.days(3))
                .retry(maxCount: 2, interval: .seconds(1))
                .placeholder { ProgressView() }
                .onFailure { error in
                    MXLog.error("KingFisher: Failed to load feed media image: \(error)")
                    didFail = true
                }
                .onSuccess { result in
                    MXLog.info("KingFisher: Media Loaded from: \(result.cacheType)")
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
