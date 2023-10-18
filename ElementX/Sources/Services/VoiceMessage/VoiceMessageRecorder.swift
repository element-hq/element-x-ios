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

class VoiceMessageRecorder: VoiceMessageRecorderProtocol {
    private let audioRecorder: AudioRecorderProtocol
    private let audioConverter: AudioConverterProtocol
    private let voiceMessageCache: VoiceMessageCacheProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    
    var recordingURL: URL? {
        audioRecorder.url
    }
    
    private(set) var recordingDuration: TimeInterval = 0.0
    private(set) var recordingWaveform: [UInt16] = []
    
    private(set) var previewPlayerState: AudioPlayerState?
    
    init(audioRecorder: AudioRecorderProtocol = AudioRecorder(),
         mediaPlayerProvider: MediaPlayerProviderProtocol,
         audioConverter: AudioConverterProtocol = AudioConverter(),
         voiceMessageCache: VoiceMessageCacheProtocol = VoiceMessageCache()) {
        self.audioRecorder = audioRecorder
        self.mediaPlayerProvider = mediaPlayerProvider
        self.audioConverter = audioConverter
        self.voiceMessageCache = voiceMessageCache
    }

    func stop() async throws {
        if audioRecorder.isRecording {
            try await stopRecording()
        }
        await stopPlayback()
    }
    
    // MARK: - Recording
    
    @MainActor
    func startRecording() -> AudioRecorderProtocol {
        audioRecorder.record()
        return audioRecorder
    }
    
    func stopRecording() async throws {
        recordingDuration = audioRecorder.currentTime
        try await audioRecorder.stopRecording()
                        
        // TODO: waveform analysis
        let waveform: [UInt16] = []
        
        // Build the preview audio player state
        let audioPlayerState = await AudioPlayerState(duration: recordingDuration, waveform: Waveform(data: waveform))
        previewPlayerState = audioPlayerState
    }
    
    func cancelRecording() async throws {
        try await audioRecorder.stopRecording()
        audioRecorder.deleteRecording()
    }
    
    // MARK: - Preview
        
    func startPlayback() async throws {
        guard let previewPlayerState, let url = audioRecorder.url else {
            MXLog.error("no available preview")
            return
        }
        
        let audioPlayer = try audioPlayer()
        if audioPlayer.url == url {
            audioPlayer.play()
            return
        }
        
        await previewPlayerState.attachAudioPlayer(audioPlayer)
        let pendingMediaSource = MediaSourceProxy(url: url, mimeType: "audio/m4a")
        audioPlayer.load(mediaSource: pendingMediaSource, using: url, autoplay: true)
    }
    
    func pausePlayback() {
        let audioPlayer = try? audioPlayer()
        audioPlayer?.pause()
    }
    
    func stopPlayback() async {
        await previewPlayerState?.detachAudioPlayer()
        let audioPlayer = try? audioPlayer()
        audioPlayer?.stop()
    }
    
    func seekPlayback(to progress: Double) async {
        await previewPlayerState?.updateState(progress: progress)
    }
    
    // MARK: - Pending Voice Message
    
    func deleteRecording() {
        audioRecorder.deleteRecording()
    }
    
    // MARK: - Private
    
    private func audioPlayer() throws -> AudioPlayerProtocol {
        guard let url = audioRecorder.url else {
            throw VoiceMessageRecorderError.previewNotAvailable
        }
        let mediaSource = MediaSourceProxy(url: url, mimeType: "audio/m4a")
        guard let audioPlayer = try mediaPlayerProvider.player(for: mediaSource) as? AudioPlayerProtocol else {
            throw VoiceMessageRecorderError.previewNotAvailable
        }
        return audioPlayer
    }
}
