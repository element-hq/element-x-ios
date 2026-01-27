//
// Copyright 2025 Element Creations Ltd.
// Copyright 2024-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import XCTest

@MainActor
class HomeScreenRoomTests: XCTestCase {
    var roomSummary: RoomSummary!
    
    func setupRoomSummary(isMarkedUnread: Bool,
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
    
    func testNoBadge() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertFalse(room.isHighlighted)
        XCTAssertFalse(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    func testAllBadgesExceptMute() {
        setupRoomSummary(isMarkedUnread: true,
                         unreadMessagesCount: 5,
                         unreadMentionsCount: 5,
                         unreadNotificationsCount: 5,
                         notificationMode: .allMessages,
                         hasOngoingCall: true)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertTrue(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertTrue(room.badges.isMentionShown)
    }
    
    func testUnhighlightedDot() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 5,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertFalse(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    func testHighlightedDot() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 5,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    func testHighlightedMentionAndDot() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 5,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertTrue(room.badges.isMentionShown)
    }
    
    func testUnhighlightedCall() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: true)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertFalse(room.isHighlighted)
        XCTAssertFalse(room.badges.isDotShown)
        XCTAssertTrue(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    func testMentionAndKeywordsUnhighlightedDot() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 10,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .mentionsAndKeywordsOnly,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertFalse(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    func testMentionAndKeywordsUnhighlightedDotHidden() {
        setupRoomSummary(isMarkedUnread: false,
                         unreadMessagesCount: 10,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .mentionsAndKeywordsOnly,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: true)
        
        XCTAssertFalse(room.isHighlighted)
        XCTAssertFalse(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    // MARK: - Mark unread
    
    func testMarkedUnreadDot() {
        setupRoomSummary(isMarkedUnread: true,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 0,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
    
    func testMarkedUnreadDotAndMention() {
        setupRoomSummary(isMarkedUnread: true,
                         unreadMessagesCount: 0,
                         unreadMentionsCount: 5,
                         unreadNotificationsCount: 0,
                         notificationMode: .allMessages,
                         hasOngoingCall: false)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertFalse(room.badges.isCallShown)
        XCTAssertFalse(room.badges.isMuteShown)
        XCTAssertTrue(room.badges.isMentionShown)
    }
    
    func testMarkedUnreadMuteDotAndCall() {
        setupRoomSummary(isMarkedUnread: true,
                         unreadMessagesCount: 5,
                         unreadMentionsCount: 5,
                         unreadNotificationsCount: 5,
                         notificationMode: .mute,
                         hasOngoingCall: true)
        
        let room = HomeScreenRoom(summary: roomSummary, hideUnreadMessagesBadge: false)
        
        XCTAssertTrue(room.isHighlighted)
        XCTAssertTrue(room.badges.isDotShown)
        XCTAssertTrue(room.badges.isCallShown)
        XCTAssertTrue(room.badges.isMuteShown)
        XCTAssertFalse(room.badges.isMentionShown)
    }
}
