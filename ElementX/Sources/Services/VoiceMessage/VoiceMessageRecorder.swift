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

enum VoiceMessageRecorderError: Error {
    case genericError
    case previewNotAvailable
}

protocol VoiceMessageRecorderProtocol {
    var previewPlayerState: AudioPlayerState? { get }
    
    @MainActor func startRecording() -> AudioRecorderProtocol
    func stopRecording() async throws
    func startPlayingRecordedVoiceMessage() async
    func stopPlayingRecordedVoiceMessage()
    func seekRecordedVoiceMessage(to progress: Double) async
    func deleteRecordedVoiceMessage()
}

class VoiceMessageRecorder: VoiceMessageRecorderProtocol {
    private let audioRecorder: AudioRecorderProtocol
    private let audioConverter: AudioConverterProtocol
    private let voiceMessageCache: VoiceMessageCacheProtocol
    var audioPlayer: AudioPlayerProtocol?
    
    private(set) var previewPlayerState: AudioPlayerState?
    
    init(audioRecorder: AudioRecorderProtocol = AudioRecorder(),
         audioConverter: AudioConverterProtocol = AudioConverter(),
         voiceMessageCache: VoiceMessageCacheProtocol = VoiceMessageCache()) {
        self.audioRecorder = audioRecorder
        self.audioConverter = audioConverter
        self.voiceMessageCache = voiceMessageCache
    }

    // MARK: - Recording
    
    @MainActor
    func startRecording() -> AudioRecorderProtocol {
        audioRecorder.record()
        return audioRecorder
    }
    
    func stopRecording() async throws {
        let duration = audioRecorder.currentTime
        audioRecorder.stopRecording()
                        
        // TODO: waveform analysis
        let waveform: [UInt16] = []
        
        // Build the preview audio player state
        let audioPlayerState = await AudioPlayerState(duration: duration, waveform: Waveform(data: waveform))
        previewPlayerState = audioPlayerState
    }
    
    // MARK: - Preview
    
    func startPlayingRecordedVoiceMessage() async {
        guard let previewPlayerState, let url = audioRecorder.url else {
            MXLog.error("no available preview")
            return
        }
        
        if let audioPlayer, audioPlayer.url == url {
            audioPlayer.play()
            return
        }
        
        let audioPlayer = AudioPlayer()
        self.audioPlayer = audioPlayer
        
        await previewPlayerState.attachAudioPlayer(audioPlayer)
        let pendingMediaSource = MediaSourceProxy(url: url, mimeType: "audio/m4a")
        audioPlayer.load(mediaSource: pendingMediaSource, using: url, autoplay: true)
    }
    
    func stopPlayingRecordedVoiceMessage() {
        audioPlayer?.pause()
    }
    
    func seekRecordedVoiceMessage(to progress: Double) async {
        await previewPlayerState?.updateState(progress: progress)
    }
    
    // MARK: - Pending Voice Message
    
    func deleteRecordedVoiceMessage() {
        audioRecorder.deleteRecording()
    }
}
