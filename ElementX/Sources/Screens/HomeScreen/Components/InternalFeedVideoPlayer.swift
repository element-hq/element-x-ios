//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import AVKit

struct InternalFeedVideoPlayer : View {
    let videoURL: URL
    @StateObject private var viewModel = VideoPlayerViewModel()
    
    var body: some View {
        ZStack {
            if let player = viewModel.player {
                VideoPlayer(player: player)
            } else {
                ProgressView()
            }
        }
        .onAppear {
            viewModel.setup(url: videoURL)
        }
        .onDisappear {
            viewModel.cleanup()
        }
    }
}

private final class VideoPlayerViewModel: ObservableObject {
    @Published var player: AVPlayer?
    @Published var failedToLoad: Bool = false

    private var playerItemObservation: NSKeyValueObservation?

    func setup(url: URL) {
        MXLog.info("VIDEO_URL_REQUESTED: \(url.absoluteString)")
        let item = AVPlayerItem(url: url)

        // Observe status
        playerItemObservation = item.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            if item.status == .failed {
                DispatchQueue.main.async {
                    self?.failedToLoad = true
                    MXLog.error("❌ Video failed to load: \(item.error?.localizedDescription ?? "Unknown error")")
                }
            }
        }

        let player = AVPlayer(playerItem: item)
        self.player = player
    }

    func cleanup() {
        player?.pause()
        player = nil
        playerItemObservation = nil
    }
}
