//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import VideoPlayer
import CoreMedia

struct PostVideoPlayerView: View {
    let videoURL: URL
    //    @StateObject private var viewModel = VideoPlayerViewModel()
    
    @State private var play: Bool = false
    @State private var showControls: Bool = true
    @State private var isLoading: Bool = false
    @State private var time: CMTime = .zero
        
    var body: some View {
        ZStack {
            VideoPlayer(url: videoURL, play: $play, time: $time)
                .onPlayToEndTime {
                    showControls = true
                    time = .zero
                }
                .onStateChanged { state in
                    switch state {
                    case .loading:
                        isLoading = true
                    case .playing(_):
                        isLoading = false
                    case .error(let error):
                        MXLog.error("Failed to load video: \(error)")
                    default:
                        break
                    }
                }
            
            if showControls {
                Button {
                    play.toggle()
                    showControls = !play
                } label: {
                    Image(systemName: play ? "pause.fill" : "play.fill")
                        .resizable()
                        .frame(width: 24, height: 24)
                        .padding()
                        .background(.black)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                        .aspectRatio(contentMode: .fit)
                }
            }
            
            if isLoading {
                ProgressView().frame(maxWidth: .infinity)
            }
        }
        .onTapGesture {
            showControls = !showControls
        }
        //        ZStack {
        //            if let player = viewModel.player {
        //                VideoPlayer(player: player)
        //            } else {
        //                ProgressView()
        //            }
        //        }
        //        .onAppear {
        //            viewModel.setup(url: videoURL)
        //        }
        //        .onDisappear {
        //            viewModel.cleanup()
        //        }
    }
}

//private final class VideoPlayerViewModel: ObservableObject {
//    @Published var player: AVPlayer?
//    @Published var failedToLoad: Bool = false
//
//    private var playerItemObservation: NSKeyValueObservation?
//
//    func setup(url: URL) {
//        MXLog.info("VIDEO_URL_REQUESTED: \(url.absoluteString)")
//        let item = AVPlayerItem(url: url)
//
//        // Observe status
//        playerItemObservation = item.observe(\.status, options: [.new, .initial]) { [weak self] item, _ in
//            if item.status == .failed {
//                DispatchQueue.main.async {
//                    self?.failedToLoad = true
//                    MXLog.error("❌ Video failed to load: \(item.error?.localizedDescription ?? "Unknown error")")
//                }
//            }
//        }
//
//        let player = AVPlayer(playerItem: item)
//        self.player = player
//    }
//
//    func cleanup() {
//        player?.pause()
//        player = nil
//        playerItemObservation = nil
//    }
//}
