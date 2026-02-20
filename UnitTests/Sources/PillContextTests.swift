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

@Suite
@MainActor
struct PillContextTests {
    @Test
    func user() async {
        let id = "@test:matrix.org"
        let proxyMock = JoinedRoomProxyMock(.init(name: "Test"))
        let subject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
        proxyMock.membersPublisher = subject.asCurrentValuePublisher()
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: MockTimelineController(),
                                     userSession: UserSessionMock(.init()),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics,
                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                     linkMetadataProvider: LinkMetadataProvider(),
                                     timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .user(userID: id), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(context.viewState.displayText == id)
        
        let name = "Mr. Test"
        let avatarURL = URL(string: "https://test.jpg")
        subject.send([RoomMemberProxyMock(with: .init(userID: id, displayName: name, avatarURL: avatarURL, membership: .join))])
        await Task.yield()
        
        #expect(!context.viewState.isOwnMention)
        #expect(context.viewState.displayText == "@\(name)")
    }
    
    @Test
    func ownUser() {
        let id = "@test:matrix.org"
        let proxyMock = JoinedRoomProxyMock(.init(name: "Test", ownUserID: id))
        let subject = CurrentValueSubject<[RoomMemberProxyProtocol], Never>([])
        proxyMock.membersPublisher = subject.asCurrentValuePublisher()
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: MockTimelineController(),
                                     userSession: UserSessionMock(.init()),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics,
                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                     linkMetadataProvider: LinkMetadataProvider(),
                                     timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .user(userID: id), font: .preferredFont(forTextStyle: .body)))
        
        #expect(context.viewState.isOwnMention)
    }
    
    @Test
    func allUsers() {
        let avatarURL = URL(string: "https://matrix.jpg")
        let id = "test_room"
        let displayName = "Test"
        let proxyMock = JoinedRoomProxyMock(.init(id: id, name: displayName, avatarURL: avatarURL))
        let mockController = MockTimelineController()
        mockController.roomProxy = proxyMock
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: mockController,
                                     userSession: UserSessionMock(.init()),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics,
                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                     linkMetadataProvider: LinkMetadataProvider(),
                                     timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .allUsers, font: .preferredFont(forTextStyle: .body)))
        
        #expect(context.viewState.isOwnMention)
        #expect(context.viewState.displayText == PillUtilities.atRoom)
    }
    
    @Test
    func roomIDMention() {
        let proxyMock = JoinedRoomProxyMock(.init())
        let mockController = MockTimelineController()
        let clientMock = ClientProxyMock(.init())
        clientMock.roomSummaryForIdentifierReturnValue = .mock(id: "1", name: "Foundation 🔭🪐🌌")
        mockController.roomProxy = proxyMock
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: mockController,
                                     userSession: UserSessionMock(.init(clientProxy: clientMock)),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics,
                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                     linkMetadataProvider: LinkMetadataProvider(),
                                     timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .roomID("1"), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "#Foundation 🔭🪐🌌")
    }
    
    @Test
    func roomIDMentionMissingRoom() {
        let proxyMock = JoinedRoomProxyMock(.init())
        let mockController = MockTimelineController()
        mockController.roomProxy = proxyMock
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: mockController,
                                     userSession: UserSessionMock(.init()),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics,
                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                     linkMetadataProvider: LinkMetadataProvider(),
                                     timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .roomID("1"), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "1")
    }
    
    @Test
    func roomAliasMention() {
        let proxyMock = JoinedRoomProxyMock(.init())
        let mockController = MockTimelineController()
        mockController.roomProxy = proxyMock
        let clientMock = ClientProxyMock(.init())
        clientMock.roomSummaryForAliasReturnValue = .mock(id: "2",
                                                          name: "Foundation and Empire",
                                                          canonicalAlias: "#foundation-and-empire:matrix.org")
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: mockController,
                                     userSession: UserSessionMock(.init(clientProxy: clientMock)),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics,
                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                     linkMetadataProvider: LinkMetadataProvider(),
                                     timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .roomAlias("#foundation-and-empire:matrix.org"), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "#Foundation and Empire")
    }
    
    @Test
    func roomAliasMentionMissingRoom() {
        let proxyMock = JoinedRoomProxyMock(.init())
        let mockController = MockTimelineController()
        mockController.roomProxy = proxyMock
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: mockController,
                                     userSession: UserSessionMock(.init()),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics,
                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                     linkMetadataProvider: LinkMetadataProvider(),
                                     timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .roomAlias("#foundation-and-empire:matrix.org"), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "#foundation-and-empire:matrix.org")
    }
    
    @Test
    func eventOnRoomIDMention() {
        let proxyMock = JoinedRoomProxyMock(.init())
        let mockController = MockTimelineController()
        mockController.roomProxy = proxyMock
        let clientMock = ClientProxyMock(.init())
        clientMock.roomSummaryForIdentifierReturnValue = .mock(id: "1", name: "Foundation 🔭🪐🌌")
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: mockController,
                                     userSession: UserSessionMock(.init(clientProxy: clientMock)),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics,
                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                     linkMetadataProvider: LinkMetadataProvider(),
                                     timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .event(room: .roomID("1")), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "💬 > #Foundation 🔭🪐🌌")
    }
    
    @Test
    func eventOnRoomIDMentionMissingRoom() {
        let proxyMock = JoinedRoomProxyMock(.init())
        let mockController = MockTimelineController()
        mockController.roomProxy = proxyMock
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: mockController,
                                     userSession: UserSessionMock(.init()),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics,
                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                     linkMetadataProvider: LinkMetadataProvider(),
                                     timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .event(room: .roomID("1")), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "💬 > 1")
    }
    
    @Test
    func eventOnRoomAliasMention() {
        let proxyMock = JoinedRoomProxyMock(.init())
        let mockController = MockTimelineController()
        mockController.roomProxy = proxyMock
        let clientMock = ClientProxyMock(.init())
        clientMock.roomSummaryForAliasReturnValue = .mock(id: "2",
                                                          name: "Foundation and Empire",
                                                          canonicalAlias: "#foundation-and-empire:matrix.org")
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: mockController,
                                     userSession: UserSessionMock(.init(clientProxy: clientMock)),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics,
                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                     linkMetadataProvider: LinkMetadataProvider(),
                                     timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .event(room: .roomAlias("#foundation-and-empire:matrix.org")), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "💬 > #Foundation and Empire")
    }
    
    @Test
    func eventOnRoomAliasMentionMissingRoom() {
        let proxyMock = JoinedRoomProxyMock(.init())
        let mockController = MockTimelineController()
        mockController.roomProxy = proxyMock
        let mock = TimelineViewModel(roomProxy: proxyMock,
                                     timelineController: mockController,
                                     userSession: UserSessionMock(.init()),
                                     mediaPlayerProvider: MediaPlayerProviderMock(),
                                     userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                     appMediator: AppMediatorMock.default,
                                     appSettings: ServiceLocator.shared.settings,
                                     analyticsService: ServiceLocator.shared.analytics,
                                     emojiProvider: EmojiProvider(appSettings: ServiceLocator.shared.settings),
                                     linkMetadataProvider: LinkMetadataProvider(),
                                     timelineControllerFactory: TimelineControllerFactoryMock(.init()))
        let context = PillContext(timelineContext: mock.context, data: PillTextAttachmentData(type: .event(room: .roomAlias("#foundation-and-empire:matrix.org")), font: .preferredFont(forTextStyle: .body)))
        
        #expect(!context.viewState.isOwnMention)
        #expect(!context.viewState.isUndefined)
        #expect(context.viewState.displayText == "💬 > #foundation-and-empire:matrix.org")
    }
}
