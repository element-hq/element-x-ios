//
// Copyright 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
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
                    rooms = rooms.filter { $0.name.localizedCaseInsensitiveContains(query) }
                }
                
                roomListSubject.send(rooms)
            case let .all(filters):
                var rooms = initialRooms
                
                if filters.count > 1 {
                    // for testing purpose chaining more than one filter will always return an empty state
                    rooms = []
                } else if let filter = filters.first {
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
        RoomSummary(roomListItem: RoomListItemSDKMock(),
                    id: "1",
                    isInvite: false,
                    inviter: nil,
                    name: "Foundation 🔭🪐🌌",
                    isDirect: false,
                    avatarURL: nil,
                    heroes: [],
                    lastMessage: AttributedString("I do not wish to take the trouble to understand mysticism"),
                    lastMessageFormattedTimestamp: "14:56",
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: .allMessages,
                    canonicalAlias: nil,
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false),
        RoomSummary(roomListItem: RoomListItemSDKMock(),
                    id: "2",
                    isInvite: false,
                    inviter: nil,
                    name: "Foundation and Empire",
                    isDirect: false,
                    avatarURL: URL.picturesDirectory,
                    heroes: [],
                    lastMessage: AttributedString("How do you see the Emperor then? You think he keeps office hours?"),
                    lastMessageFormattedTimestamp: "2:56 PM",
                    unreadMessagesCount: 2,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 2,
                    notificationMode: .mute,
                    canonicalAlias: nil,
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false),
        RoomSummary(roomListItem: RoomListItemSDKMock(),
                    id: "3",
                    isInvite: false,
                    inviter: nil,
                    name: "Second Foundation",
                    isDirect: false,
                    avatarURL: nil,
                    heroes: [],
                    lastMessage: try? AttributedString(markdown: "He certainly seemed no *mental genius* to me"),
                    lastMessageFormattedTimestamp: "Some time ago",
                    unreadMessagesCount: 3,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: .mentionsAndKeywordsOnly,
                    canonicalAlias: nil,
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false),
        RoomSummary(roomListItem: RoomListItemSDKMock(),
                    id: "4",
                    isInvite: false,
                    inviter: nil,
                    name: "Foundation's Edge",
                    isDirect: false,
                    avatarURL: nil,
                    heroes: [],
                    lastMessage: AttributedString("There's an archaic measure of time that's called the month"),
                    lastMessageFormattedTimestamp: "Just now",
                    unreadMessagesCount: 2,
                    unreadMentionsCount: 2,
                    unreadNotificationsCount: 2,
                    notificationMode: .allMessages,
                    canonicalAlias: nil,
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false),
        RoomSummary(roomListItem: RoomListItemSDKMock(),
                    id: "5",
                    isInvite: false,
                    inviter: nil,
                    name: "Foundation and Earth",
                    isDirect: true,
                    avatarURL: nil,
                    heroes: [],
                    lastMessage: AttributedString("Clearly, if Earth is powerful enough to do that, it might also be capable of adjusting minds in order to force belief in its radioactivity"),
                    lastMessageFormattedTimestamp: "1986",
                    unreadMessagesCount: 1,
                    unreadMentionsCount: 1,
                    unreadNotificationsCount: 1,
                    notificationMode: .allMessages,
                    canonicalAlias: nil,
                    hasOngoingCall: true,
                    isMarkedUnread: false,
                    isFavourite: false),
        RoomSummary(roomListItem: RoomListItemSDKMock(),
                    id: "6",
                    isInvite: false,
                    inviter: nil,
                    name: "Prelude to Foundation",
                    isDirect: true,
                    avatarURL: nil,
                    heroes: [],
                    lastMessage: AttributedString("Are you groping for the word 'paranoia'?"),
                    lastMessageFormattedTimestamp: "きょうはじゅういちがつじゅういちにちです",
                    unreadMessagesCount: 6,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: .mute,
                    canonicalAlias: nil,
                    hasOngoingCall: true,
                    isMarkedUnread: false,
                    isFavourite: false),
        RoomSummary(roomListItem: RoomListItemSDKMock(),
                    id: "0",
                    isInvite: false,
                    inviter: nil,
                    name: "Unknown",
                    isDirect: false,
                    avatarURL: nil,
                    heroes: [],
                    lastMessage: nil,
                    lastMessageFormattedTimestamp: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: nil,
                    canonicalAlias: nil,
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false)
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
                        
                        let room = RoomSummary(roomListItem: RoomListItemSDKMock(),
                                               id: "\(id)",
                                               settingsMode: mode,
                                               hasUnreadMessages: hasUnreadMessages,
                                               hasUnreadMentions: hasUnreadMentions,
                                               hasUnreadNotifications: hasUnreadNotifications)
                        
                        result.append(room)
                    }
                }
            }
        }
        
        return result
    }()
    
    static let mockInvites: [Element] = [
        RoomSummary(roomListItem: RoomListItemSDKMock(),
                    id: "someAwesomeRoomId1",
                    isInvite: false,
                    inviter: RoomMemberProxyMock.mockCharlie,
                    name: "First room",
                    isDirect: false,
                    avatarURL: URL.picturesDirectory,
                    heroes: [],
                    lastMessage: nil,
                    lastMessageFormattedTimestamp: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: nil,
                    canonicalAlias: "#footest:somewhere.org",
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false),
        RoomSummary(roomListItem: RoomListItemSDKMock(),
                    id: "someAwesomeRoomId2",
                    isInvite: false,
                    inviter: RoomMemberProxyMock.mockCharlie,
                    name: "Second room",
                    isDirect: true,
                    avatarURL: nil,
                    heroes: [],
                    lastMessage: nil,
                    lastMessageFormattedTimestamp: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: nil,
                    canonicalAlias: nil,
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false)
    ]
}
