//
// Copyright 2024 New Vector Ltd
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

enum RoomSummaryProviderMockConfigurationState {
    case loading
    case loaded([RoomSummary])
}

struct RoomSummaryProviderMockConfiguration {
    var state: RoomSummaryProviderMockConfigurationState = .loading
}

extension RoomSummaryProviderMock {
    convenience init(_ configuration: RoomSummaryProviderMockConfiguration) {
        self.init()
        
        let initialRooms: [RoomSummary]
        let roomListSubject: CurrentValueSubject<[RoomSummary], Never>
        let stateSubject: CurrentValueSubject<RoomSummaryProviderState, Never>
        
        switch configuration.state {
        case .loading:
            initialRooms = []
            roomListSubject = .init(initialRooms)
            stateSubject = .init(.notLoaded)
        case .loaded(let rooms):
            initialRooms = rooms
            roomListSubject = .init(initialRooms)
            stateSubject = .init(.loaded(totalNumberOfRooms: UInt(rooms.count)))
        }
        
        roomListPublisher = roomListSubject.asCurrentValuePublisher()
        statePublisher = stateSubject.asCurrentValuePublisher()
        
        setFilterClosure = { [initialRooms, roomListSubject] filter in
            switch filter {
            case let .search(query):
                var rooms = initialRooms
                
                if !query.isEmpty {
                    rooms = rooms.filter { $0.name?.localizedCaseInsensitiveContains(query) ?? false }
                }
                
                roomListSubject.send(rooms)
            case let .all(filters):
                var rooms = initialRooms
                
                if let filter = filters.first {
                    rooms = rooms.filter { filter == .people ? $0.isDirect : !$0.isDirect }
                }
                
                roomListSubject.send(rooms)
            case .excludeAll:
                roomListSubject.send([])
            }
        }
    }
}

extension Array where Element == RoomSummary {
    static let mockRooms: [Element] = [
        .filled(details: RoomSummaryDetails(id: "1",
                                            name: "Foundation 🔭🪐🌌",
                                            isDirect: false,
                                            avatarURL: nil,
                                            lastMessage: AttributedString("I do not wish to take the trouble to understand mysticism"),
                                            lastMessageFormattedTimestamp: "14:56",
                                            unreadMessagesCount: 0,
                                            unreadMentionsCount: 0,
                                            unreadNotificationsCount: 0,
                                            notificationMode: .allMessages,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: false,
                                            isMarkedUnread: false,
                                            isFavourite: false)),
        .filled(details: RoomSummaryDetails(id: "2",
                                            name: "Foundation and Empire",
                                            isDirect: false,
                                            avatarURL: URL.picturesDirectory,
                                            lastMessage: AttributedString("How do you see the Emperor then? You think he keeps office hours?"),
                                            lastMessageFormattedTimestamp: "2:56 PM",
                                            unreadMessagesCount: 2,
                                            unreadMentionsCount: 0,
                                            unreadNotificationsCount: 2,
                                            notificationMode: .mute,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: false,
                                            isMarkedUnread: false,
                                            isFavourite: false)),
        .filled(details: RoomSummaryDetails(id: "3",
                                            name: "Second Foundation",
                                            isDirect: false,
                                            avatarURL: nil,
                                            lastMessage: try? AttributedString(markdown: "He certainly seemed no *mental genius* to me"),
                                            lastMessageFormattedTimestamp: "Some time ago",
                                            unreadMessagesCount: 3,
                                            unreadMentionsCount: 0,
                                            unreadNotificationsCount: 0,
                                            notificationMode: .mentionsAndKeywordsOnly,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: false,
                                            isMarkedUnread: false,
                                            isFavourite: false)),
        .filled(details: RoomSummaryDetails(id: "4",
                                            name: "Foundation's Edge",
                                            isDirect: false,
                                            avatarURL: nil,
                                            lastMessage: AttributedString("There's an archaic measure of time that's called the month"),
                                            lastMessageFormattedTimestamp: "Just now",
                                            unreadMessagesCount: 2,
                                            unreadMentionsCount: 2,
                                            unreadNotificationsCount: 2,
                                            notificationMode: .allMessages,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: false,
                                            isMarkedUnread: false,
                                            isFavourite: false)),
        .filled(details: RoomSummaryDetails(id: "5",
                                            name: "Foundation and Earth",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: AttributedString("Clearly, if Earth is powerful enough to do that, it might also be capable of adjusting minds in order to force belief in its radioactivity"),
                                            lastMessageFormattedTimestamp: "1986",
                                            unreadMessagesCount: 1,
                                            unreadMentionsCount: 1,
                                            unreadNotificationsCount: 1,
                                            notificationMode: .allMessages,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: true,
                                            isMarkedUnread: false,
                                            isFavourite: false)),
        .filled(details: RoomSummaryDetails(id: "6",
                                            name: "Prelude to Foundation",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: AttributedString("Are you groping for the word 'paranoia'?"),
                                            lastMessageFormattedTimestamp: "きょうはじゅういちがつじゅういちにちです",
                                            unreadMessagesCount: 6,
                                            unreadMentionsCount: 0,
                                            unreadNotificationsCount: 0,
                                            notificationMode: .mute,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: true,
                                            isMarkedUnread: false,
                                            isFavourite: false)),
        .filled(details: RoomSummaryDetails(id: "0",
                                            name: "Unknown",
                                            isDirect: false,
                                            avatarURL: nil,
                                            lastMessage: nil,
                                            lastMessageFormattedTimestamp: nil,
                                            unreadMessagesCount: 0,
                                            unreadMentionsCount: 0,
                                            unreadNotificationsCount: 0,
                                            notificationMode: nil,
                                            canonicalAlias: nil,
                                            inviter: nil,
                                            hasOngoingCall: false,
                                            isMarkedUnread: false,
                                            isFavourite: false)),
        .empty
    ]
    
    static let mockRoomsWithNotificationsState: [Element] = {
        var result: [Element] = []

        // Iterate over settings modes
        for mode in RoomNotificationModeProxy.allCases {
            // Iterate over unread messages states
            for hasUnreadMessages in [false, true] {
                // Iterate over unread mentions states
                for hasUnreadMentions in [false, true] {
                    // Iterate over unread notifications states
                    for hasUnreadNotifications in [false, true] {
                        // Incrementing id value for each combination
                        let id = result.count + 1

                        let room = RoomSummary.filled(details: RoomSummaryDetails(id: "\(id)",
                                                                                  settingsMode: mode,
                                                                                  hasUnreadMessages: hasUnreadMessages,
                                                                                  hasUnreadMentions: hasUnreadMentions,
                                                                                  hasUnreadNotifications: hasUnreadNotifications))

                        result.append(room)
                    }
                }
            }
        }

        return result
    }()
    
    static let mockInvites: [Element] = [
        .filled(details: RoomSummaryDetails(id: "someAwesomeRoomId1", name: "First room",
                                            isDirect: false,
                                            avatarURL: URL.picturesDirectory,
                                            lastMessage: nil,
                                            lastMessageFormattedTimestamp: nil,
                                            unreadMessagesCount: 0,
                                            unreadMentionsCount: 0,
                                            unreadNotificationsCount: 0,
                                            notificationMode: nil,
                                            canonicalAlias: "#footest:somewhere.org",
                                            inviter: RoomMemberProxyMock.mockCharlie,
                                            hasOngoingCall: false,
                                            isMarkedUnread: false,
                                            isFavourite: false)),
        .filled(details: RoomSummaryDetails(id: "someAwesomeRoomId2",
                                            name: "Second room",
                                            isDirect: true,
                                            avatarURL: nil,
                                            lastMessage: nil,
                                            lastMessageFormattedTimestamp: nil,
                                            unreadMessagesCount: 0,
                                            unreadMentionsCount: 0,
                                            unreadNotificationsCount: 0,
                                            notificationMode: nil,
                                            canonicalAlias: nil,
                                            inviter: RoomMemberProxyMock.mockCharlie,
                                            hasOngoingCall: false,
                                            isMarkedUnread: false,
                                            isFavourite: false))
    ]
}
