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
            roomListSubject.send(initialRooms)
            stateSuject = .init(.notLoaded)
        case .loaded(let rooms):
            initialRooms = rooms
            roomListSubject = .init(initialRooms)
            roomListSubject.send(initialRooms)
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
            if filter.isEmpty {
                roomListSubject.send(initialRooms)
            } else {
                roomListSubject.send(initialRooms.filter { $0.name?.localizedCaseInsensitiveContains(filter) ?? false })
            }
        }
    }
}

extension Array where Element == RoomSummary {
    static let mockRooms: [Element] = [
        .filled(details: RoomSummaryDetails(id: "1",
                                            name: "Foundation 🔭🪐🌌",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: AttributedString("I do not wish to take the trouble to understand mysticism"),
                                            lastMessageFormattedTimestamp: "14:56",
                                            unreadNotificationCount: 0,
                                            notificationMode: .allMessages,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: false)),
        .filled(details: RoomSummaryDetails(id: "2",
                                            name: "Foundation and Empire",
                                            isDirect: true,
                                            avatarURL: URL.picturesDirectory,
                                            lastMessage: AttributedString("How do you see the Emperor then? You think he keeps office hours?"),
                                            lastMessageFormattedTimestamp: "2:56 PM",
                                            unreadNotificationCount: 2,
                                            notificationMode: .mute,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: false)),
        .filled(details: RoomSummaryDetails(id: "3",
                                            name: "Second Foundation",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: try? AttributedString(markdown: "He certainly seemed no *mental genius* to me"),
                                            lastMessageFormattedTimestamp: "Some time ago",
                                            unreadNotificationCount: 3,
                                            notificationMode: .mentionsAndKeywordsOnly,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: false)),
        .filled(details: RoomSummaryDetails(id: "4",
                                            name: "Foundation's Edge",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: AttributedString("There's an archaic measure of time that's called the month"),
                                            lastMessageFormattedTimestamp: "Just now",
                                            unreadNotificationCount: 4,
                                            notificationMode: .allMessages,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: false)),
        .filled(details: RoomSummaryDetails(id: "5",
                                            name: "Foundation and Earth",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: AttributedString("Clearly, if Earth is powerful enough to do that, it might also be capable of adjusting minds in order to force belief in its radioactivity"),
                                            lastMessageFormattedTimestamp: "1986",
                                            unreadNotificationCount: 5,
                                            notificationMode: .allMessages,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: true)),
        .filled(details: RoomSummaryDetails(id: "6",
                                            name: "Prelude to Foundation",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: AttributedString("Are you groping for the word 'paranoia'?"),
                                            lastMessageFormattedTimestamp: "きょうはじゅういちがつじゅういちにちです",
                                            unreadNotificationCount: 6,
                                            notificationMode: .mute,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: true)),
        .filled(details: RoomSummaryDetails(id: "0",
                                            name: "Unknown",
                                            isDirect: false,
                                            avatarURL: nil,
                                            lastMessage: nil,
                                            lastMessageFormattedTimestamp: nil,
                                            unreadNotificationCount: 0,
                                            notificationMode: nil,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: false)),
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
                                            inviter: RoomMemberProxyMock.mockCharlie,
                                            hasOngoingCall: false)),
        .filled(details: RoomSummaryDetails(id: "someAwesomeRoomId2",
                                            name: "Second room",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: nil,
                                            lastMessageFormattedTimestamp: nil,
                                            unreadNotificationCount: 0,
                                            notificationMode: nil,
                                            canonicalAlias: nil,
                                            inviter: RoomMemberProxyMock.mockCharlie,
                                            hasOngoingCall: false))
    ]
}
