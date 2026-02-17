//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
@Suite
struct HomeScreenRoomTests {
    var roomSummary: RoomSummary!
    
    mutating func setupRoomSummary(isMarkedUnread: Bool,
                                   unreadMessagesCount: UInt,
                                   unreadMentionsCount: UInt,
                                   unreadNotificationsCount: UInt,
                                   notificationMode: RoomNotificationModeProxy,
                                   hasOngoingCall: Bool) {
        roomSummary = RoomSummary(room: .init(noHandle: .init()),
                                  id: "Test room",
                                  joinRequestType: nil,
                                  name: "Test room",
                                  isDirect: false,
                                  isSpace: false,
                                  avatarURL: nil,
                                  heroes: [],
                                  activeMembersCount: 0,
                                  lastMessage: nil,
                                  lastMessageDate: nil,
                                  lastMessageState: nil,
                                  unreadMessagesCount: unreadMessagesCount,
                                  unreadMentionsCount: unreadMentionsCount,
                                  unreadNotificationsCount: unreadNotificationsCount,
                                  notificationMode: notificationMode,
                                  canonicalAlias: nil,
                                  alternativeAliases: [],
                                  hasOngoingCall: hasOngoingCall,
                                  isMarkedUnread: isMarkedUnread,
                                  isFavourite: false,
                                  isTombstoned: false)
    }
    
    @Test
    mutating func noBadge() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        #expect(!room.isHighlighted)
        #expect(!room.badges.isDotShown)
        #expect(!room.badges.isCallShown)
        #expect(!room.badges.isMuteShown)
        #expect(!room.badges.isMentionShown)
    }
    
    @Test
    mutating func allBadgesExceptMute() {
        setupRoomSummary(isMarkedUnread: true,
                         unreadMessagesCount: 5,
                         unreadMentionsCount: 5,
                         unreadNotificationsCount: 5,
                         notificationMode: .allMessages,
                         hasOngoingCall: true)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        #expect(room.isHighlighted)
        #expect(room.badges.isDotShown)
        #expect(room.badges.isCallShown)
        #expect(!room.badges.isMuteShown)
        #expect(room.badges.isMentionShown)
    }
    
    @Test
    mutating func unhighlightedDot() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 5,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        #expect(!room.isHighlighted)
        #expect(room.badges.isDotShown)
        #expect(!room.badges.isCallShown)
        #expect(!room.badges.isMuteShown)
        #expect(!room.badges.isMentionShown)
    }
    
    @Test
    mutating func highlightedDot() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 5,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        #expect(room.isHighlighted)
        #expect(room.badges.isDotShown)
        #expect(!room.badges.isCallShown)
        #expect(!room.badges.isMuteShown)
        #expect(!room.badges.isMentionShown)
    }
    
    @Test
    mutating func highlightedMentionAndDot() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 5,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        #expect(room.isHighlighted)
        #expect(room.badges.isDotShown)
        #expect(!room.badges.isCallShown)
        #expect(!room.badges.isMuteShown)
        #expect(room.badges.isMentionShown)
    }
    
    @Test
    mutating func unhighlightedCall() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: true)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        #expect(!room.isHighlighted)
        #expect(!room.badges.isDotShown)
        #expect(room.badges.isCallShown)
        #expect(!room.badges.isMuteShown)
        #expect(!room.badges.isMentionShown)
    }
    
    @Test
    mutating func mentionAndKeywordsUnhighlightedDot() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 10,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .mentionsAndKeywordsOnly,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        #expect(!room.isHighlighted)
        #expect(room.badges.isDotShown)
        #expect(!room.badges.isCallShown)
        #expect(!room.badges.isMuteShown)
        #expect(!room.badges.isMentionShown)
    }
    
    @Test
    mutating func mentionAndKeywordsUnhighlightedDotHidden() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 10,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .mentionsAndKeywordsOnly,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: true)
        
        #expect(!room.isHighlighted)
        #expect(!room.badges.isDotShown)
        #expect(!room.badges.isCallShown)
        #expect(!room.badges.isMuteShown)
        #expect(!room.badges.isMentionShown)
    }
    
    // MARK: - Mark unread
    
    @Test
    mutating func markedUnreadDot() {
        setupRoomSummary(isMarkedUnread: true,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        #expect(room.isHighlighted)
        #expect(room.badges.isDotShown)
        #expect(!room.badges.isCallShown)
        #expect(!room.badges.isMuteShown)
        #expect(!room.badges.isMentionShown)
    }
    
    @Test
    mutating func markedUnreadDotAndMention() {
        setupRoomSummary(isMarkedUnread: true,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 5,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        #expect(room.isHighlighted)
        #expect(room.badges.isDotShown)
        #expect(!room.badges.isCallShown)
        #expect(!room.badges.isMuteShown)
        #expect(room.badges.isMentionShown)
    }
    
    @Test
    mutating func markedUnreadMuteDotAndCall() {
        setupRoomSummary(isMarkedUnread: true,
                         unreadMessagesCount: 5,
                         unreadMentionsCount: 5,
                         unreadNotificationsCount: 5,
                         notificationMode: .mute,
                         hasOngoingCall: true)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        #expect(room.isHighlighted)
        #expect(room.badges.isDotShown)
        #expect(room.badges.isCallShown)
        #expect(room.badges.isMuteShown)
        #expect(!room.badges.isMentionShown)
    }
}
