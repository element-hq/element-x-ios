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
    private let waveformSamplesCount = 100
    
    private(set) var recordingURL: URL?
    private(set) var recordingDuration: TimeInterval = 0.0
    
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
    
    func startRecording() async throws {
        await stopPlayback()
        recordingURL = nil
        try await audioRecorder.record(withId: UUID().uuidString)
        recordingURL = audioRecorder.url
    }
    
    func stopRecording() async throws {
        recordingDuration = audioRecorder.currentTime
        try await audioRecorder.stopRecording()
                
        // Build the preview audio player state
        previewPlayerState = await AudioPlayerState(duration: recordingDuration, waveform: EstimatedWaveform(data: []))
    }
    
    func cancelRecording() async throws {
        try await audioRecorder.stopRecording()
        audioRecorder.deleteRecording()
        recordingURL = nil
        previewPlayerState = nil
    }
    
    func deleteRecording() async {
        await stopPlayback()
        audioRecorder.deleteRecording()
        previewPlayerState = nil
        recordingURL = nil
    }

    // MARK: - Preview
        
    func startPlayback() async throws {
        guard let previewPlayerState, let url = recordingURL else {
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
        guard let previewPlayerState else {
            return
        }
        await previewPlayerState.detachAudioPlayer()
        let audioPlayer = try? audioPlayer()
        audioPlayer?.stop()
    }
    
    func seekPlayback(to progress: Double) async {
        await previewPlayerState?.updateState(progress: progress)
    }
    
    func buildRecordingWaveform() async throws -> [UInt16] {
        guard let url = recordingURL else {
            MXLog.error("no recording file")
            return []
        }
        // build the waveform
        var waveformData: [UInt16] = []
        let analyzer = WaveformAnalyzer()
        do {
            let samples = try await analyzer.samples(fromAudioAt: url, count: 100)
            // linearly normalized to [0, 1] (1 -> -50 dB)
            waveformData = samples.map { UInt16(max(0, (1 - $0) * 1024)) }
        } catch {
            MXLog.error("Waveform analysis failed: \(error)")
        }
        return waveformData
    }
        
    // MARK: - Private
    
    private func audioPlayer() throws -> AudioPlayerProtocol {
        guard let url = recordingURL else {
            throw VoiceMessageRecorderError.previewNotAvailable
        }
        let mediaSource = MediaSourceProxy(url: url, mimeType: mp4accMimeType)
        guard let audioPlayer = try mediaPlayerProvider.player(for: mediaSource) as? AudioPlayerProtocol else {
            throw VoiceMessageRecorderError.previewNotAvailable
        }
        return audioPlayer
    }
}
