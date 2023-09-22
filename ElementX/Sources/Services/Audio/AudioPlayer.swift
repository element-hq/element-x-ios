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

import AVFoundation
import Combine
import Foundation
import UIKit

enum AudioPlayerError: Error {
    case genericError
}

class AudioPlayer: NSObject, AudioPlayerProtocol {
    private(set) var mediaSource: MediaSourceProxy?
    private var mediaFileHandle: MediaFileHandleProxy?
    
    private var playerItem: AVPlayerItem?
    private var audioPlayer: AVQueuePlayer?
    
    private var cancellables = Set<AnyCancellable>()
    private let callbacksSubject: PassthroughSubject<AudioPlayerCallback, Never> = .init()
    var callbacks: AnyPublisher<AudioPlayerCallback, Never> {
        callbacksSubject.eraseToAnyPublisher()
    }
    
    private var statusObserver: NSKeyValueObservation?
    private var playbackBufferEmptyObserver: NSKeyValueObservation?
    private var rateObserver: NSKeyValueObservation?
    private var playToEndObserver: NSObjectProtocol?
    private var appBackgroundObserver: NSObjectProtocol?
    
    private var contentURL: URL?
    
    var url: URL? {
        mediaSource?.url
    }
    
    private(set) var displayName: String?
    
    var duration: TimeInterval {
        abs(CMTimeGetSeconds(audioPlayer?.currentItem?.duration ?? .zero))
    }
    
    var currentTime: TimeInterval {
        let currentTime = abs(CMTimeGetSeconds(audioPlayer?.currentTime() ?? .zero))
        return currentTime.isFinite ? currentTime : .zero
    }
    
    var playerItems: [AVPlayerItem] {
        guard let audioPlayer else {
            return []
        }
        
        return audioPlayer.items()
    }
    
    var currentUrl: URL? {
        (audioPlayer?.currentItem?.asset as? AVURLAsset)?.url
    }
    
    var state: MediaPlayerState {
        if isStopped {
            return .stopped
        }
        if isPlaying {
            return .playing
        }
        if isPaused {
            return .paused
        }
        return .stopped
    }
    
    private var isStopped = true
    
    private var isPlaying: Bool {
        guard let audioPlayer else {
            return false
        }
        
        return audioPlayer.currentItem != nil && audioPlayer.rate > 0
    }
    
    private var isPaused: Bool {
        guard let audioPlayer else {
            return false
        }
        
        return audioPlayer.currentItem != nil && audioPlayer.rate == 0
    }
    
    deinit {
        removeObservers()
        unloadContent()
    }
    
    func loadContent(mediaSource: MediaSourceProxy, mediaFileHandle: MediaFileHandleProxy, displayName: String? = nil) async throws {
        if self.mediaFileHandle == mediaFileHandle {
            return
        }
        
        self.mediaSource = mediaSource
        self.mediaFileHandle = mediaFileHandle
        self.displayName = displayName
        
        removeObservers()
        
        dispatchCallback(.didStartLoading)
        
        // Convert from ogg if needed
        contentURL = mediaFileHandle.url
        
        if !mediaFileHandle.url.hasSupportedAudioExtension {
            let identifier = UUID().uuidString
            let uniqueFolder = FileManager.default.temporaryDirectory.appendingPathComponent(identifier)
            var newURL = uniqueFolder.appendingPathComponent(mediaFileHandle.url.lastPathComponent).deletingPathExtension()
            let fileExtension = newURL.hasSupportedAudioExtension ? newURL.pathExtension : "m4a"
            newURL.appendPathExtension(fileExtension)
            
            do {
                try FileManager.default.createDirectory(at: uniqueFolder, withIntermediateDirectories: true)
                try await AudioConverter.convertToMPEG4AACIfNeeded(sourceURL: mediaFileHandle.url, destinationURL: newURL)
                contentURL = newURL
            } catch {
                throw AudioPlayerError.genericError
            }
        }
        
        guard let contentURL else {
            throw AudioPlayerError.genericError
        }
        
        playerItem = AVPlayerItem(url: contentURL)
        audioPlayer = AVQueuePlayer(playerItem: playerItem)
        
        addObservers()
    }
    
    func reloadContentIfNeeded() async throws {
        if let mediaSource, let mediaFileHandle, let audioPlayer, audioPlayer.currentItem == nil {
            MXLog.debug("[AudioPlayer] reloading content...")
            self.mediaFileHandle = nil
            try await loadContent(mediaSource: mediaSource, mediaFileHandle: mediaFileHandle)
        }
    }
    
    func removeAllPlayerItems() {
        audioPlayer?.removeAllItems()
    }
    
    func unloadContent() {
        mediaSource = nil
        mediaFileHandle = nil
        contentURL = nil
        audioPlayer?.replaceCurrentItem(with: nil)
    }
    
    func play() async throws {
        isStopped = false
        
        try await reloadContentIfNeeded()
        
        do {
            try AVAudioSession.sharedInstance().setCategory(AVAudioSession.Category.playback)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            MXLog.error("[AudioPlayer] Could not redirect audio playback to speakers.")
        }
        
        MXLog.debug("[AudioPlayer] playing...")
        audioPlayer?.play()
    }
    
    func pause() {
        audioPlayer?.pause()
    }
    
    func stop() {
        if isStopped {
            return
        }
        
        isStopped = true
        audioPlayer?.pause()
        audioPlayer?.seek(to: .zero)
    }
    
    func seek(to progress: Double) async {
        MXLog.debug("[AudioPlayer] seek(to: \(progress)")
        let time = progress * duration
        await audioPlayer?.seek(to: CMTime(seconds: time, preferredTimescale: 60000))
    }
    
    // MARK: - Private
    
    private func addObservers() {
        guard let audioPlayer, let playerItem else {
            return
        }
        
        statusObserver = playerItem.observe(\.status, options: [.old, .new]) { [weak self] _, _ in
            guard let self else { return }
            
            switch playerItem.status {
            case .failed:
                self.dispatchCallback(.didFailWithError(error: playerItem.error ?? AudioPlayerError.genericError))
            case .readyToPlay:
                self.dispatchCallback(.didFinishLoading)
            default:
                break
            }
        }
        
        playbackBufferEmptyObserver = playerItem.observe(\.isPlaybackBufferEmpty, options: [.old, .new]) { [weak self] _, _ in
            guard let self else { return }
            
            if playerItem.isPlaybackBufferEmpty {
                self.dispatchCallback(.didStartLoading)
            } else {
                self.dispatchCallback(.didFinishLoading)
            }
        }
        
        rateObserver = audioPlayer.observe(\.rate, options: [.old, .new]) { [weak self] _, _ in
            guard let self else { return }
            
            if audioPlayer.rate == 0.0 {
                if self.isStopped {
                    self.dispatchCallback(.didStopPlaying)
                } else {
                    self.dispatchCallback(.didPausePlaying)
                }
            } else {
                self.dispatchCallback(.didStartPlaying)
            }
        }
                
        NotificationCenter.default.publisher(for: Notification.Name.AVPlayerItemDidPlayToEndTime)
            .sink { [weak self] _ in
                guard let self else { return }
                self.dispatchCallback(.didFinishPlaying)
            }
            .store(in: &cancellables)
        
        // Request authorization uppon UIApplication.didBecomeActiveNotification notification
        NotificationCenter.default.publisher(for: UIApplication.didEnterBackgroundNotification)
            .sink { [weak self] _ in
                guard let self else { return }
                self.pause()
                self.dispatchCallback(.didPausePlaying)
            }
            .store(in: &cancellables)
    }
    
    private func removeObservers() {
        statusObserver?.invalidate()
        playbackBufferEmptyObserver?.invalidate()
        rateObserver?.invalidate()
        cancellables.removeAll()
    }
    
    private func dispatchCallback(_ callback: AudioPlayerCallback) {
        callbacksSubject.send(callback)
    }
}
