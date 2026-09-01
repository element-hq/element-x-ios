//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

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
    
    /// Plays a short sound on top of whatever is already playing. It goes through the app's own
    /// audio session, so unlike the sounds built into iOS it is heard in silent mode too.
    func play(soundEffect: SoundEffect)
}

// sourcery: AutoMockable
extension MediaPlayerProviderProtocol { }
