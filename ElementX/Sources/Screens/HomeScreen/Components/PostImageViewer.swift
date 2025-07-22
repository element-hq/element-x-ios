//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import Kingfisher

struct PostImageViewer: View {
    let mediaInfo: HomeScreenPostMediaInfo
    let mediaUrl: URL?
    let onMediaTapped: () -> Void
    let onReloadMedia: () -> Void
    
    @State private var didFail = false
    
    var body: some View {
        if didFail {
            ZStack {
                RefreshButton(onRefresh: { onReloadMedia() })
            }
            .frame(maxWidth: .infinity, minHeight: 300)
            .cornerRadius(4)
        } else if let mediaUrl {
            KFAnimatedImage(mediaUrl)
                .placeholder { ProgressView() }
                .onFailure { error in
                    ZeroCustomEventService.shared.feedScreenEvent(parameters: [
                        "type": "Feed Media Preview Image",
                        "status": "Failure",
                        "mediaId" : mediaInfo.id,
                        "mediaUrl": mediaUrl.absoluteString,
                        "error": error.localizedDescription
                    ])
                    didFail = true
                }
                .onSuccess { _ in
                    didFail = false
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
