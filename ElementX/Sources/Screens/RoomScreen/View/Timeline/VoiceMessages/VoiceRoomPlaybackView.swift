//
// Copyright 2023 New Vector Ltd
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

import SwiftUI

enum PlaybackState: Equatable {
    case disabled
    case paused
    case playing
    case recording
}

struct VoiceRoomPlaybackView: View {
    @ObservedObject var context: VoiceRoomPlaybackViewModel.Context
    
    var body: some View {
        HStack {
            HStack {
                playPauseButton
                Text(context.viewState.currentTime)
                    .font(.compound.bodySMSemibold)
                    .foregroundColor(.compound.textSecondary)
                    .monospacedDigit()
            }
            .padding(.vertical, 6)
            GeometryReader { geometry in
                WaveformView(waveform: context.viewState.waveform, progress: context.viewState.progress)
                    .gesture(DragGesture(minimumDistance: 10, coordinateSpace: .local)
                        .onChanged { value in
                            let position = value.location.x / geometry.size.width
                            if abs(position - context.viewState.progress) > 0.01 {
                                context.send(viewAction: .seek(position: max(0, min(position, 1.0))))
                            }
                        }
                        .onEnded { value in
                            let position = value.location.x / geometry.size.width
                            context.send(viewAction: .seek(position: max(0, min(position, 1.0))))
                        }
                    )
            }
            .frame(maxWidth: 150)
        }
        .padding(.vertical, 2)
        .padding(.horizontal, 8)
    }
    
    var playPauseButton: some View {
        Button {
            context.send(viewAction: .playPauseButtonTapped)
        } label: {
            Image(systemName: context.viewState.playing ? "pause.fill" : "play.fill")
                .foregroundColor(.compound.iconSecondary)
                .background(
                    Circle()
                        .frame(width: 32, height: 32)
                        .foregroundColor(.compound.bgCanvasDefault)
                )
                .padding(.trailing, 7)
        }
    }
}

struct VoiceRoomPlaybackView_Previews: PreviewProvider {
    static let waveform = Waveform(data: [3, 127, 400, 266, 126, 122, 373, 251, 45, 112,
                                          334, 205, 99, 138, 397, 354, 125, 361, 199, 51,
                                          294, 131, 19, 2, 3, 3, 1, 2, 0, 0,
                                          0, 0, 0, 0, 0, 3])
    
    static let viewModel = {
        let timelineItem = VoiceRoomTimelineItem(id: .random,
                                                 timestamp: "5 PM",
                                                 isOutgoing: false,
                                                 isEditable: false,
                                                 sender: .init(id: "", displayName: "Bob"),
                                                 content: .init(body: "Voice message",
                                                                duration: 10.0,
                                                                waveform: waveform,
                                                                source: nil,
                                                                contentType: nil))
        var model = VoiceRoomPlaybackViewModel(timelineItem: timelineItem)

        return model
    }()
    
    static var previews: some View {
        VoiceRoomPlaybackView(context: viewModel.context)
            .fixedSize(horizontal: false, vertical: true)
    }
}
