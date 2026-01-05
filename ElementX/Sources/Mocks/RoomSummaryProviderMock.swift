//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDKMocks

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

extension RoomSummary {
    static func mock(id: String,
                     name: String,
                     canonicalAlias: String? = nil) -> RoomSummary {
        RoomSummary(room: RoomSDKMock(),
                    id: id,
                    joinRequestType: nil,
                    name: name,
                    isDirect: false,
                    isSpace: false,
                    avatarURL: nil,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: AttributedString("I do not wish to take the trouble to understand mysticism"),
                    lastMessageDate: .mock,
                    lastMessageState: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: .allMessages,
                    canonicalAlias: canonicalAlias,
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: false)
    }
}

extension Array where Element == RoomSummary {
    static let mockRooms: [Element] = [
        RoomSummary(room: RoomSDKMock(),
                    id: "1",
                    joinRequestType: nil,
                    name: "Foundation 🔭🪐🌌",
                    isDirect: false,
                    isSpace: false,
                    avatarURL: nil,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: AttributedString("I do not wish to take the trouble to understand mysticism"),
                    lastMessageDate: .mock,
                    lastMessageState: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: .allMessages,
                    canonicalAlias: nil,
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: false),
        RoomSummary(room: RoomSDKMock(),
                    id: "2",
                    joinRequestType: nil,
                    name: "Foundation and Empire",
                    isDirect: false,
                    isSpace: false,
                    avatarURL: .mockMXCAvatar,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: AttributedString("How do you see the Emperor then? You think he keeps office hours?"),
                    lastMessageDate: .mock,
                    lastMessageState: nil,
                    unreadMessagesCount: 2,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 2,
                    notificationMode: .mute,
                    canonicalAlias: "#foundation-and-empire:matrix.org",
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: false),
        RoomSummary(room: RoomSDKMock(),
                    id: "3",
                    joinRequestType: nil,
                    name: "Second Foundation",
                    isDirect: false,
                    isSpace: false,
                    avatarURL: nil,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: try? AttributedString(markdown: "He certainly seemed no *mental genius* to me"),
                    lastMessageDate: .mock,
                    lastMessageState: nil,
                    unreadMessagesCount: 3,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: .mentionsAndKeywordsOnly,
                    canonicalAlias: nil,
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: false),
        RoomSummary(room: RoomSDKMock(),
                    id: "4",
                    joinRequestType: nil,
                    name: "Foundation's Edge",
                    isDirect: false,
                    isSpace: false,
                    avatarURL: nil,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: AttributedString("There's an archaic measure of time that's called the month"),
                    lastMessageDate: .mock,
                    lastMessageState: nil,
                    unreadMessagesCount: 2,
                    unreadMentionsCount: 2,
                    unreadNotificationsCount: 2,
                    notificationMode: .allMessages,
                    canonicalAlias: nil,
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: false),
        RoomSummary(room: RoomSDKMock(),
                    id: "5",
                    joinRequestType: nil,
                    name: "Foundation and Earth",
                    isDirect: true,
                    isSpace: false,
                    avatarURL: nil,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: AttributedString("Clearly, if Earth is powerful enough to do that, it might also be capable of adjusting minds in order to force belief in its radioactivity"),
                    lastMessageDate: .mock,
                    lastMessageState: nil,
                    unreadMessagesCount: 1,
                    unreadMentionsCount: 1,
                    unreadNotificationsCount: 1,
                    notificationMode: .allMessages,
                    canonicalAlias: nil,
                    alternativeAliases: [],
                    hasOngoingCall: true,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: false),
        RoomSummary(room: RoomSDKMock(),
                    id: "6",
                    joinRequestType: nil,
                    name: "Prelude to Foundation",
                    isDirect: true,
                    isSpace: false,
                    avatarURL: nil,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: AttributedString("Are you groping for the word 'paranoia'?"),
                    lastMessageDate: .mock,
                    lastMessageState: nil,
                    unreadMessagesCount: 6,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: .mute,
                    canonicalAlias: "#prelude-foundation:matrix.org",
                    alternativeAliases: [],
                    hasOngoingCall: true,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: false),
        RoomSummary(room: RoomSDKMock(),
                    id: "7",
                    joinRequestType: nil,
                    name: "Tombstoned",
                    isDirect: false,
                    isSpace: false,
                    avatarURL: nil,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: nil,
                    lastMessageDate: .mock,
                    lastMessageState: nil,
                    unreadMessagesCount: 1,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 1,
                    notificationMode: .allMessages,
                    canonicalAlias: nil,
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: true),
        RoomSummary(room: RoomSDKMock(),
                    id: "0",
                    joinRequestType: nil,
                    name: "Unknown",
                    isDirect: false,
                    isSpace: false,
                    avatarURL: nil,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: nil,
                    lastMessageDate: nil,
                    lastMessageState: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: nil,
                    canonicalAlias: nil,
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: false)
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
                        
                        let room = RoomSummary(room: RoomSDKMock(),
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
        RoomSummary(room: RoomSDKMock(),
                    id: "someAwesomeRoomId1",
                    joinRequestType: .invite(inviter: RoomMemberProxyMock.mockCharlie),
                    name: "First room",
                    isDirect: false,
                    isSpace: false,
                    avatarURL: .mockMXCAvatar,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: nil,
                    lastMessageDate: nil,
                    lastMessageState: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: nil,
                    canonicalAlias: "#footest:somewhere.org",
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: false),
        RoomSummary(room: RoomSDKMock(),
                    id: "someAwesomeRoomId2",
                    joinRequestType: .invite(inviter: RoomMemberProxyMock.mockCharlie),
                    name: "Second room",
                    isDirect: true,
                    isSpace: false,
                    avatarURL: nil,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: nil,
                    lastMessageDate: nil,
                    lastMessageState: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: nil,
                    canonicalAlias: nil,
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: false)
    ]
    
    static let mockSpaceInvites: [Element] = [
        RoomSummary(room: RoomSDKMock(),
                    id: "!space1:matrix.org",
                    joinRequestType: .invite(inviter: RoomMemberProxyMock.mockCharlie),
                    name: "First space",
                    isDirect: false,
                    isSpace: true,
                    avatarURL: .mockMXCAvatar,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: nil,
                    lastMessageDate: nil,
                    lastMessageState: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: nil,
                    canonicalAlias: "#footest:somewhere.org",
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: false),
        RoomSummary(room: RoomSDKMock(),
                    id: "!space2:matrix.org",
                    joinRequestType: .invite(inviter: RoomMemberProxyMock.mockCharlie),
                    name: "Second space",
                    isDirect: false,
                    isSpace: true,
                    avatarURL: nil,
                    heroes: [],
                    activeMembersCount: 0,
                    lastMessage: nil,
                    lastMessageDate: nil,
                    lastMessageState: nil,
                    unreadMessagesCount: 0,
                    unreadMentionsCount: 0,
                    unreadNotificationsCount: 0,
                    notificationMode: nil,
                    canonicalAlias: nil,
                    alternativeAliases: [],
                    hasOngoingCall: false,
                    isMarkedUnread: false,
                    isFavourite: false,
                    isTombstoned: false)
    ]
}
