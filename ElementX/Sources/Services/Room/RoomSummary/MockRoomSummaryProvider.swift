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

enum MockRoomSummaryProviderState {
    case loading
    case loaded
}

class MockRoomSummaryProvider: RoomSummaryProviderProtocol {
    let roomListUpdatePublisher: CurrentValueSubject<[RoomSummaryProviderRoom], Never>
    let stateUpdatePublisher: CurrentValueSubject<RoomSummaryProviderState, Never>
    let countUpdatePublisher: CurrentValueSubject<UInt, Never>
    
    func updateRoomsWithIdentifiers(_ identifiers: [String]) { }
    
    convenience init() {
        self.init(state: .loading)
    }
    
    init(state: MockRoomSummaryProviderState) {
        switch state {
        case .loading:
            roomListUpdatePublisher = .init([])
            stateUpdatePublisher = .init(.cold)
            countUpdatePublisher = .init(0)
        case .loaded:
            roomListUpdatePublisher = .init(Self.rooms)
            stateUpdatePublisher = .init(.live)
            countUpdatePublisher = .init(UInt(Self.rooms.count))
        }
    }
    
    // MARK: - Private
    
    static let rooms: [RoomSummaryProviderRoom] = [
        .filled(roomSummary: RoomSummary(id: "1", name: "First room",
                                         isDirect: true,
                                         avatarURLString: nil,
                                         lastMessage: AttributedString("Prosciutto beef ribs pancetta filet mignon kevin hamburger, chuck ham venison picanha. Beef ribs chislic turkey biltong tenderloin."),
                                         lastMessageTimestamp: .now,
                                         unreadNotificationCount: 4)),
        .filled(roomSummary: RoomSummary(id: "2",
                                         name: "Second room",
                                         isDirect: true,
                                         avatarURLString: "mockImageURLString",
                                         lastMessage: nil,
                                         lastMessageTimestamp: nil,
                                         unreadNotificationCount: 1)),
        .filled(roomSummary: RoomSummary(id: "3",
                                         name: "Third room",
                                         isDirect: true,
                                         avatarURLString: nil,
                                         lastMessage: try? AttributedString(markdown: "**@mock:client.com**: T-bone beef ribs bacon"),
                                         lastMessageTimestamp: .now,
                                         unreadNotificationCount: 0)),
        .empty(id: "3")
    ]
}
