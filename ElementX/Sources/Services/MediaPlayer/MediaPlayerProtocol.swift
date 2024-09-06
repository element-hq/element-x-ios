//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Foundation

enum MediaPlayerState {
    case loading
    case playing
    case paused
    case stopped
    case error
}

protocol MediaPlayerProtocol: AnyObject {
    var mediaSource: MediaSourceProxy? { get }
    var duration: TimeInterval { get }
    var currentTime: TimeInterval { get }
    var url: URL? { get }
    var state: MediaPlayerState { get }
    
    func load(mediaSource: MediaSourceProxy, using url: URL, autoplay: Bool)
    func reset()
    func play()
    func pause()
    func stop()
    func seek(to progress: Double) async
}

// sourcery: AutoMockable
extension MediaPlayerProtocol { }
