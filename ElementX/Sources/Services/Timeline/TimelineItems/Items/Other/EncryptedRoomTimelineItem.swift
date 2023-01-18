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

import UIKit

struct EncryptedRoomTimelineItem: EventBasedTimelineItemProtocol, Identifiable, Hashable {
    enum EncryptionType: Hashable {
        case megolmV1AesSha2(sessionId: String)
        case olmV1Curve25519AesSha2(senderKey: String)
        case unknown
    }
    
    let id: String
    let text: String
    let encryptionType: EncryptionType
    let timestamp: String
    let groupState: TimelineItemGroupState
    let isOutgoing: Bool
    let isEditable: Bool
    
    var sender: TimelineItemSender
    
    var properties = RoomTimelineItemProperties()
}
