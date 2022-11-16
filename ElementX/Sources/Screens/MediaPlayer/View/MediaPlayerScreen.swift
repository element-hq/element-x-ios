//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import AVKit
import SwiftUI

struct MediaPlayerScreen: View {
    // MARK: Public
    
    @ObservedObject var context: MediaPlayerViewModel.Context
    
    // MARK: Views

    var body: some View {
        VideoPlayer(player: player())
            .ignoresSafeArea()
    }

    private func player() -> AVPlayer {
        let player = AVPlayer(url: context.viewState.mediaURL)
        if context.viewState.autoplay {
            player.play()
        }
        return player
    }
}

// MARK: - Previews

struct MediaPlayer_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let viewModel = MediaPlayerViewModel(mediaURL: URL(staticString: "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"),
                                                 autoplay: false)
            MediaPlayerScreen(context: viewModel.context)
        }
        .tint(.element.accent)
    }
}
