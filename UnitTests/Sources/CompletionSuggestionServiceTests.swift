//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
struct CompletionSuggestionServiceTests {
    // MARK: User Suggestions
    
    @Test("User suggestions match members but not the own user or the room without permission")
    func userSuggestions() async throws {
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
    
    @Test("User suggestions match a display name typed without its whitespace")
    func userSuggestionsMatchDisplayNameWithoutWhitespace() async throws {
        let jane = RoomMemberProxyMock(with: .init(userID: "@jdoe:matrix.org", displayName: "Jane Q Doe", membership: .join))
        let members: [RoomMemberProxyMock] = [jane, .mockAlice, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "roomID", name: "test", members: members))
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .user(.init(id: jane.userID, displayName: jane.displayName, avatarURL: jane.avatarURL)), range: .init(), rawSuggestionText: "janeqdoe")]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "janeqdoe", range: .init()))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .user(.init(id: jane.userID, displayName: jane.displayName, avatarURL: jane.avatarURL)), range: .init(), rawSuggestionText: "doe")]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "doe", range: .init()))
        try await deferred.fulfill()
    }
    
    @Test("User suggestions rank members by where the text matches, like Element Web")
    func userSuggestionsRankedByMatchPosition() async throws {
        let leeDawson = RoomMemberProxyMock(with: .init(userID: "@lee:matrix.org", displayName: "Lee Dawson", membership: .join))
        let edward = RoomMemberProxyMock(with: .init(userID: "@edward:matrix.org", displayName: "Edward", membership: .join))
        let members: [RoomMemberProxyMock] = [leeDawson, edward, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "roomID", name: "test", members: members))
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        
        var deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == []
        }
        
        try await deferred.fulfill()
        
        // "Edward" starts with the text, "Lee Dawson" only matches across words, so it comes second.
        deferred = deferFulfillment(service.suggestionsPublisher) { suggestions in
            suggestions == [.init(suggestionType: .user(.init(id: edward.userID, displayName: edward.displayName, avatarURL: edward.avatarURL)), range: .init(), rawSuggestionText: "ed"),
                            .init(suggestionType: .user(.init(id: leeDawson.userID, displayName: leeDawson.displayName, avatarURL: leeDawson.avatarURL)), range: .init(), rawSuggestionText: "ed")]
        }
        service.setSuggestionTrigger(.init(type: .user, text: "ed", range: .init()))
        try await deferred.fulfill()
    }
    
    @Test("User suggestions include everyone when the user can notify the room")
    func userSuggestionsIncludingAllUsers() async throws {
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
    
    @Test("An empty user trigger suggests everyone and all members")
    func userSuggestionsWithEmptyText() async throws {
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
    
    @Test("User suggestions work anywhere in the message")
    func userSuggestionInDifferentMessagePositions() async throws {
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
    
    @Test("User suggestions follow the mention under the cursor")
    func userSuggestionWithMultipleMentionSymbol() async throws {
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
    
    @Test("Starting a new mention refreshes the room members once")
    func userSuggestionRefreshesMembers() async throws {
        let members: [RoomMemberProxyMock] = [.mockAlice, .mockBob, .mockMe]
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "roomID", name: "test", members: members))
        let roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(.mockRooms)))
        
        let (refreshesStream, refreshesContinuation) = AsyncStream<Void>.makeStream()
        roomProxyMock.updateMembersClosure = { refreshesContinuation.yield() }
        
        let service = CompletionSuggestionService(roomProxy: roomProxyMock,
                                                  roomListPublisher: roomSummaryProvider.roomListPublisher.eraseToAnyPublisher())
        #expect(!roomProxyMock.updateMembersCalled)
        
        // Beginning a mention refreshes the members once…
        var deferred = deferFulfillment(refreshesStream) { _ in true }
        service.setSuggestionTrigger(.init(type: .user, text: "", range: .init()))
        try await deferred.fulfill()
        #expect(roomProxyMock.updateMembersCallsCount == 1)
        
        // …but typing further within the same mention doesn't refresh again.
        service.setSuggestionTrigger(.init(type: .user, text: "a", range: .init()))
        service.setSuggestionTrigger(.init(type: .user, text: "al", range: .init()))
        #expect(roomProxyMock.updateMembersCallsCount == 1)
        
        // Clearing and starting a new mention refreshes a second time.
        deferred = deferFulfillment(refreshesStream) { _ in true }
        service.setSuggestionTrigger(nil)
        service.setSuggestionTrigger(.init(type: .user, text: "", range: .init()))
        try await deferred.fulfill()
        #expect(roomProxyMock.updateMembersCallsCount == 2)
    }
    
    // MARK: Room Suggestions
    
    @Test("Room suggestions list all rooms then filter by the typed text")
    func roomSuggestions() async throws {
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
    
    @Test("Room suggestions match a room name typed without its whitespace")
    func roomSuggestionsMatchNameWithoutWhitespace() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init(id: "roomID", name: "test", members: [.mockMe]))
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
                                  rawSuggestionText: "preludeto")]
        }
        service.setSuggestionTrigger(.init(type: .room, text: "preludeto", range: .init()))
        try await deferred.fulfill()
    }
    
    @Test("Room suggestions work anywhere in the message")
    func roomSuggestionInDifferentMessagePositions() async throws {
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
    
    @Test("Room suggestions follow the trigger under the cursor")
    func roomSuggestionWithMultipleMentionSymbol() async throws {
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
    
    // MARK: Common
    
    @Test("User and room triggers in one message are handled separately")
    func suggestionsWithMultipleDifferentTriggers() async throws {
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
    
    @Test("Suggestions match text containing non-alphanumeric characters")
    func suggestionsContainingNonAlphanumericCharacters() async throws {
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
