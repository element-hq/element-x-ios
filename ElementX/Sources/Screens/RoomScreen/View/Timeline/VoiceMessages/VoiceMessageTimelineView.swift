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

import Foundation
import SwiftUI

struct VoiceMessageTimelineView: View {
    let timelineItem: AudioRoomTimelineItem
    
    var body: some View {
        TimelineStyler(timelineItem: timelineItem) {
            VoiceMessagePlaybackView(playbackData: VoiceMessagePlaybackData.mockPlaybackData, didTogglePlayPause: { _ in })
        }
    }
}
       
struct VoiceMessageTimelineView_Previews: PreviewProvider {
    static let viewModel = RoomScreenViewModel.mock
    static let waveform = Waveform(data: [3, 127, 400, 266, 126, 122, 373, 251, 45, 112,
                                          334, 205, 99, 138, 397, 354, 125, 361, 199, 51,
                                          294, 131, 19, 2, 3, 3, 1, 2, 0, 0,
                                          0, 0, 0, 0, 0, 3])
    
    static var previews: some View {
        body.environmentObject(viewModel.context)
        body
            .environment(\.timelineStyle, .plain)
            .environmentObject(viewModel.context)
    }
    
    static let audioRoomTimelineItem = AudioRoomTimelineItem(id: .random,
                                                             timestamp: "Now",
                                                             isOutgoing: false,
                                                             isEditable: false,
                                                             sender: .init(id: "Bob"),
                                                             content: .init(body: "audio.ogg",
                                                                            duration: 300,
                                                                            source: nil,
                                                                            contentType: nil))
    
    static var body: some View {
        VoiceMessageTimelineView(timelineItem: audioRoomTimelineItem)
    }
}
