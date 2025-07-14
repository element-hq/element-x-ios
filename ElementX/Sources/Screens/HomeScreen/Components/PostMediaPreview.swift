//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

struct PostMediaPreview: View {
    let externalLoading: Bool
    let mediaInfo: HomeScreenPostMediaInfo
    let mediaUrlString: String?
    let onMediaTapped: () -> Void
    let onReloadMedia: () -> Void
        
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
            if externalLoading {
                ExternalFeedVideoPlayer(videoURL: mediaURL)
                    .frame(height: 300)
                    .cornerRadius(4)
                    .onLongPressGesture {
                        onMediaTapped()
                    }
            } else {
                InternalFeedVideoPlayer(videoURL: mediaURL)
                    .frame(height: 300)
                    .cornerRadius(4)
                    .onLongPressGesture {
                        onMediaTapped()
                    }
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
        if externalLoading {
            ExternalFeedImageViewer(mediaInfo: mediaInfo,
                                    mediaUrlString: mediaUrlString,
                                    onMediaTapped: onMediaTapped,
                                    onReloadMedia: onReloadMedia)
        } else {
            InternalFeedImageViewer(mediaInfo: mediaInfo,
                                    mediaUrlString: mediaUrlString,
                                    onMediaTapped: onMediaTapped,
                                    onReloadMedia: onReloadMedia)
        }
    }
}
