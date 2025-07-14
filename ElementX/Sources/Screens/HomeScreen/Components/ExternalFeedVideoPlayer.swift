//
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI
import VideoPlayer
import CoreMedia

struct ExternalFeedVideoPlayer : View {
    let videoURL: URL
    
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
    }
}
