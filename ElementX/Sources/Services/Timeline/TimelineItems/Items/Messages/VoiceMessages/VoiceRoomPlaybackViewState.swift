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

import Combine
import Foundation

@MainActor
class VoiceRoomPlaybackViewState: ObservableObject {
    let duration: Double
    let waveform: Waveform
    @Published private(set) var loading: Bool
    @Published private(set) var playing: Bool
    @Published private(set) var progress: Double
        
    init(duration: Double = 0.0, waveform: Waveform? = nil, progress: Double = 0.0) {
        self.duration = duration
        self.waveform = waveform ?? Waveform(data: [])
        self.progress = progress
        loading = false
        playing = false
    }
    
    func updateState(progress: Double) {
        self.progress = max(0.0, min(progress, 1.0))
    }
    
    func updateState(playing: Bool) {
        self.playing = playing
    }
}
