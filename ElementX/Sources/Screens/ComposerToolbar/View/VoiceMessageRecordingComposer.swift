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

import Compound
import Foundation
import SwiftUI

struct VoiceMessageRecordingComposer: View {
    @ObservedObject var recorderState: AudioRecorderState
    
    var body: some View {
        VoiceMessageRecordingView(recorderState: recorderState)
            .padding(.vertical, 8.0)
            .padding(.horizontal, 12.0)
            .background {
                let roundedRectangle = RoundedRectangle(cornerRadius: 12)
                ZStack {
                    roundedRectangle
                        .fill(Color.compound.bgSubtleSecondary)
                }
            }
    }
    
    private func onPlaybackPlayPause() { }
    
    private func onPlaybackSeek(_ progress: Double) { }
    
    private func onPlaybackScrubbing(_ dragging: Bool) { }
}

struct VoiceMessageRecordingComposer_Previews: PreviewProvider, TestablePreview {
    static let recorderState = AudioRecorderState()
    
    static var previews: some View {
        VoiceMessageRecordingComposer(recorderState: recorderState)
            .fixedSize(horizontal: false, vertical: true)
    }
}
