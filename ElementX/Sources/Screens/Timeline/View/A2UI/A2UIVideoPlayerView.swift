//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AVKit
import SwiftUI

/// A video opened from an A2UI surface, ready to be played full screen.
struct A2UIVideoPlayback: Identifiable {
    let id = UUID()
    let url: URL
    /// Keeps a downloaded Matrix video on disk for as long as it's being played.
    let fileHandle: MediaFileHandleProxy?
}

/// Plays an A2UI video with the system player, as the media preview does for video attachments.
/// Presented from the timeline rather than the bubble, as the cells can't host view controllers.
struct A2UIVideoPlayerView: View {
    @Environment(\.dismiss) private var dismiss
    let playback: A2UIVideoPlayback
    
    var body: some View {
        ElementNavigationStack {
            A2UIPlayerViewController(url: playback.url)
                .ignoresSafeArea()
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(L10n.actionDone) { dismiss() }
                    }
                }
        }
        .preferredColorScheme(.dark)
    }
}

private struct A2UIPlayerViewController: UIViewControllerRepresentable {
    let url: URL
    
    func makeUIViewController(context: Context) -> AVPlayerViewController {
        let controller = AVPlayerViewController()
        controller.player = AVPlayer(url: url)
        controller.player?.play()
        return controller
    }
    
    func updateUIViewController(_ controller: AVPlayerViewController, context: Context) { }
}
