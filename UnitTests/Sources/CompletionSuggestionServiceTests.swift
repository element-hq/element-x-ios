//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import XCTest

@MainActor
final class CompletionSuggestionServiceTests: XCTestCase {
    private var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        cancellables.removeAll()
    }
    
    func testUserSuggestions() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        let members: [RoomMemberProxyMock] = [alice, .mockBob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "roomID", name: "test", members: members))
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .user(.init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL)), range: .init(), rawSuggestionText: "ali")]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "ali", range: .init()))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        service.setSuggestionTrigger(.init(type: .user, text: "me", range: .init()))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        service.setSuggestionTrigger(.init(type: .user, text: "room", range: .init()))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        service.setSuggestionTrigger(.init(type: .user, text: "everyon", range: .init()))
        try await deferred.fulfill()
    }
    
    func testUserSuggestionsIncludingAllUsers() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        let members: [RoomMemberProxyMock] = [alice, .mockBob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "roomID",
                                                      name: "test",
                                                      members: members,
                                                      powerLevelsConfiguration: .init(canUserTriggerRoomNotification: true)))
        
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
                
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .allUsers(.room(id: "roomID", name: "test", avatarURL: nil)), range: .init(), rawSuggestionText: "ro")]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "ro", range: .init()))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .allUsers(.room(id: "roomID", name: "test", avatarURL: nil)), range: .init(), rawSuggestionText: "every")]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "every", range: .init()))
        try await deferred.fulfill()
    }
    
    func testUserSuggestionsWithEmptyText() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        let bob: RoomMemberProxyMock = .mockBob
        let members: [RoomMemberProxyMock] = [alice, bob, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "roomID",
                                                      name: "test",
                                                      members: members,
                                                      powerLevelsConfiguration: .init(canUserTriggerRoomNotification: true)))
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
                
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .allUsers(.room(id: "roomID", name: "test", avatarURL: nil)), range: .init(), rawSuggestionText: ""),
                            .init(suggestionType: .user(.init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL)), range: .init(), rawSuggestionText: ""),
                            .init(suggestionType: .user(.init(id: bob.userID, displayName: bob.displayName, avatarURL: bob.avatarURL)), range: .init(), rawSuggestionText: "")]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "", range: .init()))
        try await deferred.fulfill()
        
        // Let's test the same with the processTextMessage method
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .allUsers(.room(id: "roomID", name: "test", avatarURL: nil)), range: .init(location: 0, length: 1), rawSuggestionText: ""),
                            .init(suggestionType: .user(.init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL)), range: .init(location: 0, length: 1), rawSuggestionText: ""),
                            .init(suggestionType: .user(.init(id: bob.userID, displayName: bob.displayName, avatarURL: bob.avatarURL)), range: .init(location: 0, length: 1), rawSuggestionText: "")]
        }
        service.processTextMessage("@", selectedRange: .init(location: 0, length: 1))
        try await deferred.fulfill()
    }
    
    func testUserSuggestionInDifferentMessagePositions() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        let members: [RoomMemberProxyMock] = [alice, .mockBob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(name: "test", members: members))
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .user(.init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL)), range: .init(location: 0, length: 3), rawSuggestionText: "al")]
        }
        service.processTextMessage("@al hello", selectedRange: .init(location: 0, length: 1))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .user(.init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL)), range: .init(location: 5, length: 3), rawSuggestionText: "al")]
        }
        service.processTextMessage("test @al", selectedRange: .init(location: 5, length: 1))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .user(.init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL)), range: .init(location: 5, length: 3), rawSuggestionText: "al")]
        }
        service.processTextMessage("test @al test", selectedRange: .init(location: 5, length: 1))
        try await deferred.fulfill()
    }
    
    func testUserSuggestionWithMultipleMentionSymbol() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        let bob: RoomMemberProxyMock = .mockBob
        let members: [RoomMemberProxyMock] = [alice, bob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(name: "test", members: members))
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        
        var deffered = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .user(.init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL)), range: .init(location: 0, length: 3), rawSuggestionText: "al")]
        }
        service.processTextMessage("@al test @bo", selectedRange: .init(location: 0, length: 1))
        try await deffered.fulfill()
        
        deffered = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .user(.init(id: bob.userID, displayName: bob.displayName, avatarURL: bob.avatarURL)), range: .init(location: 9, length: 3), rawSuggestionText: "bo")]
        }
        service.processTextMessage("@al test @bo", selectedRange: .init(location: 9, length: 1))
        try await deffered.fulfill()
        
        deffered = deferFulfillment(service.suggestionsPublisher) { suggestion in
            suggestion == []
        }
        service.processTextMessage("@al test @bo", selectedRange: .init(location: 4, length: 1))
        try await deffered.fulfill()
    }
    
    func testRoomSuggestions() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        // We keep the users in the tests since they should not appear in the suggestions when using the room trigger
        let members: [RoomMemberProxyMock] = [alice, .mockBob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "roomID", name: "test", members: members))
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        
        try await deferred.fulfill()
        
        // The empty # should trigger suggestions from any room with an alias
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .room(.init(id: "2",
                                                              canonicalAlias: "#foundation-and-empire:matrix.org",
                                                              name: "Foundation and Empire",
                                                              avatar: .room(id: "2",
                                                                            name: "Foundation and Empire",
                                                                            avatarURL: .mockMXCAvatar))),
                                  range: .init(),
                                  rawSuggestionText: ""),
                            .init(suggestionType: .room(.init(id: "6",
                                                              canonicalAlias: "#prelude-foundation:matrix.org",
                                                              name: "Prelude to Foundation",
                                                              avatar: .room(id: "6",
                                                                            name: "Prelude to Foundation",
                                                                            avatarURL: nil))),
                                  range: .init(),
                                  rawSuggestionText: "")]
        }
        service.setSuggestionTrigger(.init(type: .room, text: "", range: .init()))
        try await deferred.fulfill()
        
        // Same but with the processTextMessage method
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .room(.init(id: "2",
                                                              canonicalAlias: "#foundation-and-empire:matrix.org",
                                                              name: "Foundation and Empire",
                                                              avatar: .room(id: "2",
                                                                            name: "Foundation and Empire",
                                                                            avatarURL: .mockMXCAvatar))),
                                  range: .init(location: 0, length: 1),
                                  rawSuggestionText: ""),
                            .init(suggestionType: .room(.init(id: "6",
                                                              canonicalAlias: "#prelude-foundation:matrix.org",
                                                              name: "Prelude to Foundation",
                                                              avatar: .room(id: "6",
                                                                            name: "Prelude to Foundation",
                                                                            avatarURL: nil))),
                                  range: .init(location: 0, length: 1),
                                  rawSuggestionText: "")]
        }
        service.processTextMessage("#", selectedRange: .init(location: 0, length: 1))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .room(.init(id: "6",
                                                              canonicalAlias: "#prelude-foundation:matrix.org",
                                                              name: "Prelude to Foundation",
                                                              avatar: .room(id: "6",
                                                                            name: "Prelude to Foundation",
                                                                            avatarURL: nil))),
                                  range: .init(),
                                  rawSuggestionText: "prelude")]
        }
        service.setSuggestionTrigger(.init(type: .room, text: "prelude", range: .init()))
        try await deferred.fulfill()
    }
    
    func testRoomSuggestionInDifferentMessagePositions() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        // We keep the users in the tests since they should not appear in the suggestions when using the room trigger
        let members: [RoomMemberProxyMock] = [alice, .mockBob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "roomID", name: "test", members: members))
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .room(.init(id: "6",
                                                              canonicalAlias: "#prelude-foundation:matrix.org",
                                                              name: "Prelude to Foundation",
                                                              avatar: .room(id: "6",
                                                                            name: "Prelude to Foundation",
                                                                            avatarURL: nil))),
                                  range: .init(location: 0, length: 3),
                                  rawSuggestionText: "pr")]
        }
        service.processTextMessage("#pr hello", selectedRange: .init(location: 0, length: 1))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .room(.init(id: "6",
                                                              canonicalAlias: "#prelude-foundation:matrix.org",
                                                              name: "Prelude to Foundation",
                                                              avatar: .room(id: "6",
                                                                            name: "Prelude to Foundation",
                                                                            avatarURL: nil))),
                                  range: .init(location: 5, length: 3),
                                  rawSuggestionText: "pr")]
        }
        service.processTextMessage("test #pr", selectedRange: .init(location: 5, length: 1))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .room(.init(id: "6",
                                                              canonicalAlias: "#prelude-foundation:matrix.org",
                                                              name: "Prelude to Foundation",
                                                              avatar: .room(id: "6",
                                                                            name: "Prelude to Foundation",
                                                                            avatarURL: nil))),
                                  range: .init(location: 5, length: 3),
                                  rawSuggestionText: "pr")]
        }
        service.processTextMessage("test #pr test", selectedRange: .init(location: 5, length: 1))
        try await deferred.fulfill()
    }
    
    func testRoomSuggestionWithMultipleMentionSymbol() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        // We keep the users in the tests since they should not appear in the suggestions when using the room trigger
        let members: [RoomMemberProxyMock] = [alice, .mockBob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "roomID", name: "test", members: members))
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        
        var deffered = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .room(.init(id: "6",
                                                              canonicalAlias: "#prelude-foundation:matrix.org",
                                                              name: "Prelude to Foundation",
                                                              avatar: .room(id: "6",
                                                                            name: "Prelude to Foundation",
                                                                            avatarURL: nil))),
                                  range: .init(location: 0, length: 3),
                                  rawSuggestionText: "pr")]
        }
        service.processTextMessage("#pr test #fo", selectedRange: .init(location: 0, length: 1))
        try await deffered.fulfill()
        
        deffered = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .room(.init(id: "2",
                                                              canonicalAlias: "#foundation-and-empire:matrix.org",
                                                              name: "Foundation and Empire",
                                                              avatar: .room(id: "2",
                                                                            name: "Foundation and Empire",
                                                                            avatarURL: .mockMXCAvatar))),
                                  range: .init(location: 9, length: 3),
                                  rawSuggestionText: "fo"),
                            .init(suggestionType: .room(.init(id: "6",
                                                              canonicalAlias: "#prelude-foundation:matrix.org",
                                                              name: "Prelude to Foundation",
                                                              avatar: .room(id: "6",
                                                                            name: "Prelude to Foundation",
                                                                            avatarURL: nil))),
                                  range: .init(location: 9, length: 3),
                                  rawSuggestionText: "fo")]
        }
        service.processTextMessage("#pr test #fo", selectedRange: .init(location: 9, length: 1))
        try await deffered.fulfill()
        
        deffered = deferFulfillment(service.suggestionsPublisher) { suggestion in
            suggestion == []
        }
        service.processTextMessage("#pr test #fo", selectedRange: .init(location: 4, length: 1))
        try await deffered.fulfill()
    }
    
    func testSuggestionsWithMultipleDifferentTriggers() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        // We keep the users in the tests since they should not appear in the suggestions when using the room trigger
        let members: [RoomMemberProxyMock] = [alice, .mockBob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "roomID", name: "test", members: members))
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        
        var deffered = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .room(.init(id: "6",
                                                              canonicalAlias: "#prelude-foundation:matrix.org",
                                                              name: "Prelude to Foundation",
                                                              avatar: .room(id: "6",
                                                                            name: "Prelude to Foundation",
                                                                            avatarURL: nil))),
                                  range: .init(location: 0, length: 3),
                                  rawSuggestionText: "pr")]
        }
        service.processTextMessage("#pr test @al", selectedRange: .init(location: 0, length: 1))
        try await deffered.fulfill()
        
        deffered = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .user(.init(id: alice.userID, displayName: alice.displayName, avatarURL: alice.avatarURL)), range: .init(location: 9, length: 3), rawSuggestionText: "al")]
        }
        service.processTextMessage("#pr test @al", selectedRange: .init(location: 9, length: 1))
        try await deffered.fulfill()
    }
    
    func testSuggestionsContainingNonAlphanumericCharacters() async throws {
        let alice: RoomMemberProxyMock = .mockAlice
        // We keep the users in the tests since they should not appear in the suggestions when using the room trigger
        let members: [RoomMemberProxyMock] = [alice, .mockBob, .mockCharlie, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "roomID", name: "test", members: members))
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .room(.init(id: "6",
                                                              canonicalAlias: "#prelude-foundation:matrix.org",
                                                              name: "Prelude to Foundation",
                                                              avatar: .room(id: "6",
                                                                            name: "Prelude to Foundation",
                                                                            avatarURL: nil))),
                                  range: .init(),
                                  rawSuggestionText: "#prelude-")]
        }
        service.setSuggestionTrigger(.init(type: .room, text: "#prelude-", range: .init()))
        try await deferred.fulfill()
    }
}
