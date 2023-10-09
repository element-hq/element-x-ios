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
import MatrixRustSDK

enum MockRoomSummaryProviderState {
    case loading
    case loaded([RoomSummary])
}

class MockRoomSummaryProvider: RoomSummaryProviderProtocol {
    private let initialRooms: [RoomSummary]
    
    private let roomListSubject: CurrentValueSubject<[RoomSummary], Never>
    var roomListPublisher: CurrentValuePublisher<[RoomSummary], Never> {
        roomListSubject.asCurrentValuePublisher()
    }
    
    private let stateSuject: CurrentValueSubject<RoomSummaryProviderState, Never>
    var statePublisher: CurrentValuePublisher<RoomSummaryProviderState, Never> {
        stateSuject.asCurrentValuePublisher()
    }
    
    convenience init() {
        self.init(state: .loading)
    }
    
    init(state: MockRoomSummaryProviderState) {
        switch state {
        case .loading:
            initialRooms = []
            roomListSubject = .init(initialRooms)
            stateSuject = .init(.notLoaded)
        case .loaded(let rooms):
            initialRooms = rooms
            roomListSubject = .init(initialRooms)
            stateSuject = .init(.loaded(totalNumberOfRooms: UInt(initialRooms.count)))
        }
    }
    
    func setRoomList(_ roomList: RoomList) { }
    
    func updateVisibleRange(_ range: Range<Int>) { }
    
    func setFilter(_ filter: RoomSummaryProviderFilter) {
        switch filter {
        case .all:
            roomListSubject.send(initialRooms)
        case .none:
            roomListSubject.send([])
        case .normalizedMatchRoomName(let filter):
            roomListSubject.send(initialRooms.filter { $0.name?.localizedCaseInsensitiveContains(filter) ?? false })
        }
    }
}

extension Array where Element == RoomSummary {
    static let mockRooms: [Element] = [
        .filled(details: RoomSummaryDetails(id: "1", name: "First room",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: AttributedString("Prosciutto beef ribs pancetta filet mignon kevin hamburger, chuck ham venison picanha. Beef ribs chislic turkey biltong tenderloin."),
                                            lastMessageFormattedTimestamp: "Now",
                                            unreadNotificationCount: 4,
                                            notificationMode: .allMessages,
                                            canonicalAlias: nil,
                                            inviter: RoomMemberProxyMock.mockCharlie)),
        .filled(details: RoomSummaryDetails(id: "2",
                                            name: "Second room",
                                            isDirect: true,
                                            avatarURL: URL.picturesDirectory,
                                            lastMessage: nil,
                                            lastMessageFormattedTimestamp: nil,
                                            unreadNotificationCount: 1,
                                            notificationMode: .mentionsAndKeywordsOnly,
                                            canonicalAlias: nil,
                                            inviter: RoomMemberProxyMock.mockCharlie)),
        .filled(details: RoomSummaryDetails(id: "3",
                                            name: "Third room",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: try? AttributedString(markdown: "**@mock:client.com**: T-bone beef ribs bacon"),
                                            lastMessageFormattedTimestamp: "Later",
                                            unreadNotificationCount: 0,
                                            notificationMode: .mute,
                                            canonicalAlias: nil,
                                            inviter: RoomMemberProxyMock.mockCharlie)),
        .empty
    ]
    
    static let mockInvites: [Element] = [
        .filled(details: RoomSummaryDetails(id: "someAwesomeRoomId1", name: "First room",
                                            isDirect: false,
                                            avatarURL: URL.picturesDirectory,
                                            lastMessage: nil,
                                            lastMessageFormattedTimestamp: nil,
                                            unreadNotificationCount: 0,
                                            notificationMode: nil,
                                            canonicalAlias: "#footest:somewhere.org",
                                            inviter: RoomMemberProxyMock.mockCharlie)),
        .filled(details: RoomSummaryDetails(id: "someAwesomeRoomId2",
                                            name: "Second room",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: nil,
                                            lastMessageFormattedTimestamp: nil,
                                            unreadNotificationCount: 0,
                                            notificationMode: nil,
                                            canonicalAlias: nil,
                                            inviter: RoomMemberProxyMock.mockCharlie))
    ]
}
