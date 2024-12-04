//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation

enum AudioPlayerError: Error {
    case genericError
}

// There used to be a MediaPlayerProtocol that AudioPlayerProtocol inherited from.
// This should be called something else but we already have an AudioPlayerState,
// AudioPlayerPlaybackState and InternalAudioPlayerState so who knows what to call this.
enum MediaPlayerState {
    case loading
    case playing
    case paused
    case stopped
    case error
}

enum AudioPlayerAction {
    case didStartLoading
    case didFinishLoading
    case didStartPlaying
    case didPausePlaying
    case didStopPlaying
    case didFinishPlaying
    case didFailWithError(error: Error)
}

protocol AudioPlayerProtocol: AnyObject {
    var sourceURL: URL? { get }
    var duration: TimeInterval { get }
    var currentTime: TimeInterval { get }
    var playbackURL: URL? { get }
    var state: MediaPlayerState { get }
    
    var actions: AnyPublisher<AudioPlayerAction, Never> { get }
    
    func load(sourceURL: URL, playbackURL: URL, autoplay: Bool)
    func reset()
    func play()
    func pause()
    func stop()
    func seek(to progress: Double) async
}

// sourcery: AutoMockable
extension AudioPlayerProtocol { }
