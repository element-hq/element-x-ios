//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import AVKit

struct PostVideoPlayer : View {
    let videoURL: URL
    let onReloadMedia: () -> Void
    
    @StateObject private var viewModel = VideoPlayerViewModel()
    
    var body: some View {
        ZStack {
            if viewModel.failedToLoad {
                ZStack {
                    RefreshButton(onRefresh: { onReloadMedia() })
                }
                .frame(maxWidth: .infinity, minHeight: 300)
                .cornerRadius(4)
            } else if let player = viewModel.player {
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
        let item = AVPlayerItem(url: url)

        // Observe status
        playerItemObservation = item.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
            if item.status == .failed {
                self?.setFailedToLoad(failed: true)
                ZeroCustomEventService.shared.feedScreenEvent(parameters: [
                    "type": "Feed Media Preview Video",
                    "status": "Failure",
                    "mediaUrl": url.absoluteString,
                    "error": item.error?.localizedDescription ?? "Unknown error"
                ])
            }
            
            if item.status == .readyToPlay {
                self?.setFailedToLoad(failed: false)
            }
        }

        let player = AVPlayer(playerItem: item)
        self.player = player
    }
    
    private func setFailedToLoad(failed: Bool) {
        DispatchQueue.main.async {
            self.failedToLoad = failed
        }
    }

    func cleanup() {
        player?.pause()
        player = nil
        playerItemObservation = nil
    }
}
