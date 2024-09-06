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

enum AudioPlayerAction {
    case didStartLoading
    case didFinishLoading
    case didStartPlaying
    case didPausePlaying
    case didStopPlaying
    case didFinishPlaying
    case didFailWithError(error: Error)
}

protocol AudioPlayerProtocol: MediaPlayerProtocol {
    var actions: AnyPublisher<AudioPlayerAction, Never> { get }
}

// sourcery: AutoMockable
extension AudioPlayerProtocol { }
