//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Testing

@MainActor
struct PillContextTests {
    var membersSubject: CurrentValueSubject<[RoomMemberProxyProtocol], Never>!
    
    var viewModel: TimelineViewModel!
    
    @Test("A user mention shows the member's display name once it loads")
    mutating func user() async throws {
        setupViewModel()
        let id = "@test:matrix.org"
        let context = PillContext(timelineContext: viewModel.context, data: PillTextAttachmentData(type: .user(userID: id), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(context.viewState.displayText == id)
        
        let name = "Mr. Test"
        let avatarURL = URL(string: "https://test.jpg")
        let deferred = deferFulfillment(context.$viewState) { $0.displayText == "@\(name)" }
        membersSubject.send([RoomMemberProxyMock(with: .init(userID: id, displayName: name, avatarURL: avatarURL, membership: .join))])
        try await deferred.fulfill()
        
        #expect(!context.viewState.isOwnMention)
    }
    
    @Test("A mention of the current user is marked as their own mention")
    mutating func ownUser() {
        let id = "@test:matrix.org"
        setupViewModel(ownUserID: id)
        let context = PillContext(timelineContext: viewModel.context, data: PillTextAttachmentData(type: .user(userID: id), font: .preferredFont(forTextStyle: .body)))
        
        #expect(context.viewState.isOwnMention)
    }
    
    @Test("An @room mention is shown as a mention of the current user")
    mutating func allUsers() {
        setupViewModel()
        let context = PillContext(timelineContext: viewModel.context, data: PillTextAttachmentData(type: .allUsers, font: .preferredFont(forTextStyle: .body)))
        
        #expect(context.viewState.isOwnMention)
        #expect(context.viewState.displayText == PillUtilities.atRoom)
    }
    
    @Test("A room ID mention shows the room's name")
    mutating func roomIDMention() {
        let clientMock = ClientProxyMock(.init())
        clientMock.roomSummaryForIdentifierReturnValue = .mock(id: "1", name: "Foundation 🔭🪐🌌")
        setupViewModel(clientProxy: clientMock)
        let context = PillContext(timelineContext: viewModel.context, data: PillTextAttachmentData(type: .roomID("1"), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "#Foundation 🔭🪐🌌")
    }
    
    @Test("A room ID mention shows the raw ID when the room is unknown")
    mutating func roomIDMentionMissingRoom() {
        setupViewModel()
        let context = PillContext(timelineContext: viewModel.context, data: PillTextAttachmentData(type: .roomID("1"), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "1")
    }
    
    @Test("A room alias mention shows the room's name")
    mutating func roomAliasMention() {
        let clientMock = ClientProxyMock(.init())
        clientMock.roomSummaryForAliasReturnValue = .mock(id: "2",
                                                          name: "Foundation and Empire",
                                                          canonicalAlias: "#foundation-and-empire:matrix.org")
        setupViewModel(clientProxy: clientMock)
        let context = PillContext(timelineContext: viewModel.context, data: PillTextAttachmentData(type: .roomAlias("#foundation-and-empire:matrix.org"), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "#Foundation and Empire")
    }
    
    @Test("A room alias mention shows the raw alias when the room is unknown")
    mutating func roomAliasMentionMissingRoom() {
        setupViewModel()
        let context = PillContext(timelineContext: viewModel.context, data: PillTextAttachmentData(type: .roomAlias("#foundation-and-empire:matrix.org"), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "#foundation-and-empire:matrix.org")
    }
    
    @Test("A link to an event in a room ID shows the room's name")
    mutating func eventOnRoomIDMention() {
        let clientMock = ClientProxyMock(.init())
        clientMock.roomSummaryForIdentifierReturnValue = .mock(id: "1", name: "Foundation 🔭🪐🌌")
        setupViewModel(clientProxy: clientMock)
        let context = PillContext(timelineContext: viewModel.context, data: PillTextAttachmentData(type: .event(room: .roomID("1")), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "💬 > #Foundation 🔭🪐🌌")
    }
    
    @Test("A link to an event in a room ID shows the raw ID when the room is unknown")
    mutating func eventOnRoomIDMentionMissingRoom() {
        setupViewModel()
        let context = PillContext(timelineContext: viewModel.context, data: PillTextAttachmentData(type: .event(room: .roomID("1")), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "💬 > 1")
    }
    
    @Test("A link to an event in a room alias shows the room's name")
    mutating func eventOnRoomAliasMention() {
        let clientMock = ClientProxyMock(.init())
        clientMock.roomSummaryForAliasReturnValue = .mock(id: "2",
                                                          name: "Foundation and Empire",
                                                          canonicalAlias: "#foundation-and-empire:matrix.org")
        setupViewModel(clientProxy: clientMock)
        let context = PillContext(timelineContext: viewModel.context, data: PillTextAttachmentData(type: .event(room: .roomAlias("#foundation-and-empire:matrix.org")), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "💬 > #Foundation and Empire")
    }
    
    @Test("A link to an event in a room alias shows the raw alias when the room is unknown")
    mutating func eventOnRoomAliasMentionMissingRoom() {
        setupViewModel()
        let context = PillContext(timelineContext: viewModel.context, data: PillTextAttachmentData(type: .event(room: .roomAlias("#foundation-and-empire:matrix.org")), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "💬 > #foundation-and-empire:matrix.org")
    }
    
    // MARK: - Helpers
    
    private mutating func setupViewModel(ownUserID: String = RoomMemberProxyMock.mockMe.userID, clientProxy: ClientProxyMock = ClientProxyMock(.init())) {
        membersSubject = CurrentValueSubject([])
        
        let roomProxy = JoinedRoomProxyMock(.init(name: "Test", ownUserID: ownUserID))
        roomProxy.membersPublisher = membersSubject.asCurrentValuePublisher()
        
        viewModel = TimelineViewModel(roomProxy: roomProxy,
                                      timelineController: TimelineControllerMock(.init(roomProxy: roomProxy)),
                                      userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                      mediaPlayerProvider: MediaPlayerProviderMock(),
                                      userIndicatorController: UserIndicatorControllerMock(),
                                      appMediator: AppMediatorMock(.init()),
                                      analyticsService: AnalyticsServiceMock(.init()),
                                      emojiProvider: EmojiProvider(userSettings: .mock()),
                                      linkMetadataProvider: LinkMetadataProvider(),
                                      timelineControllerFactory: TimelineControllerFactoryMock(.init()))
    }
}
