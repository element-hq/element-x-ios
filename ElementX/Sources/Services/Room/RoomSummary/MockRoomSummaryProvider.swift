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
    let roomListPublisher: CurrentValueSubject<[RoomSummary], Never>
    let statePublisher: CurrentValueSubject<RoomSummaryProviderState, Never>
    let countPublisher: CurrentValueSubject<UInt, Never>
    
    convenience init() {
        self.init(state: .loading)
    }
    
    init(state: MockRoomSummaryProviderState) {
        switch state {
        case .loading:
            roomListPublisher = .init([])
            statePublisher = .init(.cold)
            countPublisher = .init(0)
        case .loaded:
            roomListPublisher = .init(Self.rooms)
            statePublisher = .init(.live)
            countPublisher = .init(UInt(Self.rooms.count))
        }
    }
    
    func updateVisibleRange(_ range: Range<Int>) { }
    
    // MARK: - Private
    
    static let rooms: [RoomSummary] = [
        .filled(details: RoomSummaryDetails(id: "1", name: "First room",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: AttributedString("Prosciutto beef ribs pancetta filet mignon kevin hamburger, chuck ham venison picanha. Beef ribs chislic turkey biltong tenderloin."),
                                            lastMessageFormattedTimestamp: "Now",
                                            unreadNotificationCount: 4)),
        .filled(details: RoomSummaryDetails(id: "2",
                                            name: "Second room",
                                            isDirect: true,
                                            avatarURL: URL.picturesDirectory,
                                            lastMessage: nil,
                                            lastMessageFormattedTimestamp: nil,
                                            unreadNotificationCount: 1)),
        .filled(details: RoomSummaryDetails(id: "3",
                                            name: "Third room",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: try? AttributedString(markdown: "**@mock:client.com**: T-bone beef ribs bacon"),
                                            lastMessageFormattedTimestamp: "Later",
                                            unreadNotificationCount: 0)),
        .empty
    ]
}
