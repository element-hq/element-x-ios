//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Kingfisher

struct InternalFeedImageViewer: View {
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
        if didFail {
            ZStack {
                RefreshButton(onRefresh: { onReloadMedia() })
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .cornerRadius(4)
        } else if let mediaURL {
            KFAnimatedImage(mediaURL)
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
