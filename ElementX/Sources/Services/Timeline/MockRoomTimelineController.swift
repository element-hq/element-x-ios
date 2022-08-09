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

import Combine
import Foundation

class MockRoomTimelineController: RoomTimelineControllerProtocol {
    let callbacks = PassthroughSubject<RoomTimelineControllerCallback, Never>()
    
    var timelineItems: [RoomTimelineItemProtocol] = [SeparatorRoomTimelineItem(id: UUID().uuidString,
                                                                               text: "Yesterday"),
                                                     TextRoomTimelineItem(id: UUID().uuidString,
                                                                          text: "You rock!",
                                                                          timestamp: "10:10 AM",
                                                                          shouldShowSenderDetails: true,
                                                                          isOutgoing: false,
                                                                          senderId: "",
                                                                          senderDisplayName: "Some user with a really long long long long long display name"),
                                                     TextRoomTimelineItem(id: UUID().uuidString,
                                                                          text: "You also rule!",
                                                                          timestamp: "10:11 AM",
                                                                          shouldShowSenderDetails: false,
                                                                          isOutgoing: false,
                                                                          senderId: "",
                                                                          senderDisplayName: "Alice"),
                                                     SeparatorRoomTimelineItem(id: UUID().uuidString,
                                                                               text: "Today"),
                                                     TextRoomTimelineItem(id: UUID().uuidString,
                                                                          text: "You too!",
                                                                          timestamp: "5 PM",
                                                                          shouldShowSenderDetails: false,
                                                                          isOutgoing: true,
                                                                          senderId: "",
                                                                          senderDisplayName: "Bob")]
    
    func paginateBackwards(_ count: UInt) async -> Result<Void, RoomTimelineControllerError> {
        .failure(.generic)
    }
    
    func processItemAppearance(_ itemId: String) async { }
    
    func processItemDisappearance(_ itemId: String) async { }
    
    func sendMessage(_ message: String) async { }
}
