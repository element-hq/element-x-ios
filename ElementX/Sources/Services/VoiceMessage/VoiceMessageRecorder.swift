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

import DSWaveformImage
import Foundation

class VoiceMessageRecorder: VoiceMessageRecorderProtocol {
    let audioRecorder: AudioRecorderProtocol
    private let audioConverter: AudioConverterProtocol
    private let voiceMessageCache: VoiceMessageCacheProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    
    private let mp4accMimeType = "audio/m4a"
    
    var recordingURL: URL? {
        audioRecorder.url
    }
    
    private(set) var recordingDuration: TimeInterval = 0.0
    private(set) var recordingWaveform: Waveform?
    
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
    
    // MARK: - Recording
    
    func startRecording() {
        audioRecorder.record()
    }
    
    func stopRecording() async throws {
        guard audioRecorder.isRecording else {
            return
        }
        recordingDuration = audioRecorder.currentTime
        try await audioRecorder.stopRecording()
        
        var waveformData: [UInt16] = []
        let analyzer = WaveformAnalyzer()
        if let recordingURL {
            do {
                let samples = try await analyzer.samples(fromAudioAt: recordingURL, count: 100)
                // linearly normalized to [0, 1] (1 -> -50 dB)
                waveformData = samples.map { UInt16(max(0, (1 - $0) * 1024)) }
            } catch {
                MXLog.error("Waveform analysis failed: \(error)")
            }
        }
        let waveform = Waveform(data: waveformData)
        recordingWaveform = waveform
        
        // Build the preview audio player state
        let audioPlayerState = await AudioPlayerState(duration: recordingDuration, waveform: waveform)
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
        let pendingMediaSource = MediaSourceProxy(url: url, mimeType: mp4accMimeType)
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
        let mediaSource = MediaSourceProxy(url: url, mimeType: mp4accMimeType)
        guard let audioPlayer = try mediaPlayerProvider.player(for: mediaSource) as? AudioPlayerProtocol else {
            throw VoiceMessageRecorderError.previewNotAvailable
        }
        return audioPlayer
    }
}
