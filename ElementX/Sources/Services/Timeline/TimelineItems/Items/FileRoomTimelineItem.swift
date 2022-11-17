//
// Copyright 2022 New Vector Ltd
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
import UIKit

struct FileRoomTimelineItem: EventBasedTimelineItemProtocol, Identifiable, Equatable {
    let id: String
    let text: String
    let timestamp: String
    let inGroupState: TimelineItemInGroupState
    let isOutgoing: Bool
    let isEditable: Bool
    
    let senderId: String
    var senderDisplayName: String?
    var senderAvatar: UIImage?

    let source: MediaSourceProxy?
    let thumbnailSource: MediaSourceProxy?
    var cachedFileURL: URL?
    
    var properties = RoomTimelineItemProperties()
}
