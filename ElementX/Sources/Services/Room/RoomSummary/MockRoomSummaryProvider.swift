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

class MockRoomSummaryProvider: RoomSummaryProviderProtocol {
    var callbacks = PassthroughSubject<RoomSummaryProviderCallback, Never>()
    var stateUpdatePublisher = CurrentValueSubject<RoomSummaryProviderState, Never>(.cold)
    var countUpdatePublisher = CurrentValueSubject<UInt, Never>(0)
    
    var roomSummaries: [RoomSummary] = [
        RoomSummary(id: "1", name: "First room",
                    isDirect: true,
                    avatarURLString: nil,
                    lastMessage: AttributedString("Prosciutto beef ribs pancetta filet mignon kevin hamburger, chuck ham venison picanha. Beef ribs chislic turkey biltong tenderloin."),
                    lastMessageTimestamp: .now,
                    unreadNotificationCount: 4),
        RoomSummary(id: "2",
                    name: "Second room",
                    isDirect: true,
                    avatarURLString: nil,
                    lastMessage: nil,
                    lastMessageTimestamp: nil,
                    unreadNotificationCount: 1),
        RoomSummary(id: "3",
                    name: "Third room",
                    isDirect: true,
                    avatarURLString: nil,
                    lastMessage: try? AttributedString(markdown: "**@mock:client.com**: T-bone beef ribs bacon"),
                    lastMessageTimestamp: .now,
                    unreadNotificationCount: 0)
    ]
    
    func updateRoomsWithIdentifiers(_ identifiers: [String]) { }
}
