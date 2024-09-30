//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum MediaPlayerProviderError: Error {
    case unsupportedMediaType
}

@MainActor
protocol MediaPlayerProviderProtocol {
    func player(for mediaSource: MediaSourceProxy) -> Result<MediaPlayerProtocol, MediaPlayerProviderError>
    
    func playerState(for id: AudioPlayerStateIdentifier) -> AudioPlayerState?
    func register(audioPlayerState: AudioPlayerState)
    func unregister(audioPlayerState: AudioPlayerState)
    func detachAllStates(except exception: AudioPlayerState?) async
}

// sourcery: AutoMockable
extension MediaPlayerProviderProtocol { }
