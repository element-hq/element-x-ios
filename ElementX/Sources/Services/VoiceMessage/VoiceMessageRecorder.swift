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
import MatrixRustSDK

class VoiceMessageRecorder: VoiceMessageRecorderProtocol {
    let audioRecorder: AudioRecorderProtocol
    private let audioConverter: AudioConverterProtocol
    private let voiceMessageCache: VoiceMessageCacheProtocol
    private let mediaPlayerProvider: MediaPlayerProviderProtocol
    
    private let mp4accMimeType = "audio/m4a"
    private let waveformSamplesCount = 100
    
    private(set) var recordingURL: URL?
    private(set) var recordingDuration: TimeInterval = 0.0
    
    private(set) var previewAudioPlayerState: AudioPlayerState?
    private(set) var previewAudioPlayer: AudioPlayerProtocol?
    
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
    
    func startRecording() async -> Result<Void, VoiceMessageRecorderError> {
        await stopPlayback()
        recordingURL = nil
        switch await audioRecorder.record(with: .uuid(UUID())) {
        case .failure(let error):
            return .failure(.audioRecorderError(error))
        case .success:
            recordingURL = audioRecorder.url
            return .success(())
        }
    }
    
    func stopRecording() async -> Result<Void, VoiceMessageRecorderError> {
        recordingDuration = audioRecorder.currentTime
        await audioRecorder.stopRecording()
        guard case .success = await finalizeRecording() else {
            return .failure(.previewNotAvailable)
        }
        return .success(())
    }
    
    func cancelRecording() async {
        await audioRecorder.stopRecording()
        await audioRecorder.deleteRecording()
        recordingURL = nil
        previewAudioPlayerState = nil
    }
    
    func deleteRecording() async {
        await stopPlayback()
        await audioRecorder.deleteRecording()
        previewAudioPlayerState = nil
        recordingURL = nil
    }

    // MARK: - Preview
        
    func startPlayback() async -> Result<Void, VoiceMessageRecorderError> {
        guard let previewAudioPlayerState, let url = recordingURL else {
            return .failure(.previewNotAvailable)
        }
        
        guard let audioPlayer = previewAudioPlayer else {
            return .failure(.previewNotAvailable)
        }
        
        if audioPlayer.url == url {
            audioPlayer.play()
            return .success(())
        }
        
        await previewAudioPlayerState.attachAudioPlayer(audioPlayer)
        let pendingMediaSource = MediaSourceProxy(url: url, mimeType: mp4accMimeType)
        audioPlayer.load(mediaSource: pendingMediaSource, using: url, autoplay: true)
        return .success(())
    }
    
    func pausePlayback() {
        previewAudioPlayer?.pause()
    }
    
    func stopPlayback() async {
        guard let previewAudioPlayerState else {
            return
        }
        await previewAudioPlayerState.detachAudioPlayer()
        previewAudioPlayer?.stop()
    }
    
    func seekPlayback(to progress: Double) async {
        await previewAudioPlayerState?.updateState(progress: progress)
    }
    
    func buildRecordingWaveform() async -> Result<[UInt16], VoiceMessageRecorderError> {
        guard let url = recordingURL else {
            return .failure(.missingRecordingFile)
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
        return .success(waveformData)
    }
    
    func sendVoiceMessage(inRoom roomProxy: RoomProxyProtocol, audioConverter: AudioConverterProtocol) async -> Result<Void, VoiceMessageRecorderError> {
        guard let url = recordingURL else {
            return .failure(VoiceMessageRecorderError.missingRecordingFile)
        }
        
        // convert the file
        let sourceFilename = url.deletingPathExtension().lastPathComponent
        let oggFile = URL.temporaryDirectory.appendingPathComponent(sourceFilename).appendingPathExtension("ogg")
        do {
            try audioConverter.convertToOpusOgg(sourceURL: url, destinationURL: oggFile)
        } catch {
            return .failure(.failedSendingVoiceMessage)
        }

        // send it
        let size: UInt64
        do {
            size = try UInt64(FileManager.default.sizeForItem(at: oggFile))
        } catch {
            MXLog.error("Failed to get the recording file size", context: error)
            return .failure(.failedSendingVoiceMessage)
        }
        let audioInfo = AudioInfo(duration: recordingDuration, size: size, mimetype: "audio/ogg")
        guard case .success(let waveform) = await buildRecordingWaveform() else {
            return .failure(.failedSendingVoiceMessage)
        }
        
        let result = await roomProxy.sendVoiceMessage(url: oggFile,
                                                      audioInfo: audioInfo,
                                                      waveform: waveform,
                                                      progressSubject: nil) { _ in }
        // delete the temporary file
        try? FileManager.default.removeItem(at: oggFile)
        
        if case .failure(let error) = result {
            MXLog.error("Failed to send the voice message.", context: error)
            return .failure(.failedSendingVoiceMessage)
        }
        
        return .success(())
    }
        
    // MARK: - Private
    
    private func finalizeRecording() async -> Result<Void, VoiceMessageRecorderError> {
        guard let url = recordingURL else {
            return .failure(.previewNotAvailable)
        }

        // Build the preview audio player state
        previewAudioPlayerState = await AudioPlayerState(id: .recorderPreview, duration: recordingDuration, waveform: EstimatedWaveform(data: []))

        // Build the preview audio player
        let mediaSource = MediaSourceProxy(url: url, mimeType: mp4accMimeType)
        guard case .success(let mediaPlayer) = await mediaPlayerProvider.player(for: mediaSource), let audioPlayer = mediaPlayer as? AudioPlayerProtocol else {
            return .failure(.previewNotAvailable)
        }
        previewAudioPlayer = audioPlayer
        return .success(())
    }
}
