//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

/// Short sounds played on top of whatever the app is already playing. They go through the app's
/// own audio session, so unlike the sounds built into iOS they are heard in silent mode too.
enum SoundEffect {
    /// A short, light blip.
    case tink
    
    var fileURL: URL {
        switch self {
        case .tink: URL.systemSoundsDirectory.appending(component: "Tink.caf")
        }
    }
}

protocol MediaPlayerProviderProtocol {
    var player: AudioPlayerProtocol { get }
    
    func playerState(for id: AudioPlayerStateIdentifier) -> AudioPlayerState?
    func register(audioPlayerState: AudioPlayerState)
    func unregister(audioPlayerState: AudioPlayerState)
    func detachAllStates(except exception: AudioPlayerState?) async
    
    func play(soundEffect: SoundEffect)
}

// sourcery: AutoMockable
extension MediaPlayerProviderProtocol { }
