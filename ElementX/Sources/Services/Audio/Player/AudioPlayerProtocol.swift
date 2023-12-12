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
