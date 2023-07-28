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
import MatrixRustSDK

enum RoomNotificationModeProxy {
    case allMessages
    case mentionsAndKeywordsOnly
    case mute
}

extension RoomNotificationModeProxy {
    static func from(roomNotificationMode: RoomNotificationMode) -> Self {
        switch roomNotificationMode {
        case .allMessages:
            return .allMessages
        case .mentionsAndKeywordsOnly:
            return .mentionsAndKeywordsOnly
        case .mute:
            return .mute
        }
    }
    
    var roomNotificationMode: RoomNotificationMode {
        switch self {
        case .allMessages:
            return .allMessages
        case .mentionsAndKeywordsOnly:
            return .mentionsAndKeywordsOnly
        case .mute:
            return .mute
        }
    }
}
