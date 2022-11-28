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

struct VideoPlayerScreen: View {
    @ObservedObject var context: VideoPlayerViewModel.Context

    var body: some View {
        VideoPlayer(player: player())
            .background(Color.black.ignoresSafeArea())
            .navigationBarTitleDisplayMode(.inline)
            .navigationBarBackButtonHidden()
            .toolbar { toolbar }
            .onSwipeGesture(minimumDistance: 3.0, down: {
                if context.viewState.isModallyPresented {
                    context.send(viewAction: .cancel)
                }
            }, right: {
                if !context.viewState.isModallyPresented {
                    context.send(viewAction: .cancel)
                }
            })
    }

    @ToolbarContentBuilder
    var toolbar: some ToolbarContent {
        ToolbarItem(placement: .cancellationAction) {
            Button { context.send(viewAction: .cancel) } label: {
                Image(systemName: context.viewState.isModallyPresented ? "xmark" : "chevron.backward")
                    .foregroundColor(.white)
                    .fontWeight(.semibold)
            }
            .accessibilityIdentifier("dismissButton")
        }
    }

    private func player() -> AVPlayer {
        let player = AVPlayer(url: context.viewState.videoURL)
        if context.viewState.autoplay {
            player.play()
        }
        return player
    }
}

// MARK: - Previews

struct VideoPlayer_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            let viewModel = VideoPlayerViewModel(videoURL: URL(staticString: "https://storage.googleapis.com/gtv-videos-bucket/sample/BigBuckBunny.mp4"),
                                                 autoplay: false)
            VideoPlayerScreen(context: viewModel.context)
        }
        .tint(.element.accent)
    }
}
