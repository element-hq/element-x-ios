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

import Foundation

enum MediaPlayerState {
    case prepareToPlay
    case playing
    case paused
    case stopped
}

protocol MediaPlayerProtocol {
    var mediaSource: MediaSourceProxy? { get }
    
    var currentTime: TimeInterval { get }
    var url: URL? { get }
    var state: MediaPlayerState { get }
    
    func load(mediaSource: MediaSourceProxy, mediaFileHandle: MediaFileHandleProxy) async throws
    func unloadContent()
    
    func play() async throws
    func pause()
    func stop()
    func seek(to progress: Double) async
}
