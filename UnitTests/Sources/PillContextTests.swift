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
class PillContextTests: XCTestCase {
    func testUser() async {
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
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertEqual(context.viewState.displayText, id)
        
        let name = "Mr. Test"
        let avatarURL = URL(string: "https://test.jpg")
        subject.send([RoomMemberProxyMock(with: .init(userID: id, displayName: name, avatarURL: avatarURL, membership: .join))])
        await Task.yield()
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertEqual(context.viewState.displayText, "@\(name)")
    }
    
    func testOwnUser() {
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
        
        XCTAssertTrue(context.viewState.isOwnMention)
    }
    
    func testAllUsers() {
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
        
        XCTAssertTrue(context.viewState.isOwnMention)
        XCTAssertEqual(context.viewState.displayText, PillUtilities.atRoom)
    }
    
    func testRoomIDMention() {
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
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertFalse(context.viewState.isUndefined)
        XCTAssertEqual(context.viewState.displayText, "#Foundation 🔭🪐🌌")
    }
    
    func testRoomIDMentionMissingRoom() {
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
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertFalse(context.viewState.isUndefined)
        XCTAssertEqual(context.viewState.displayText, "1")
    }
    
    func testRoomAliasMention() {
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
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertFalse(context.viewState.isUndefined)
        XCTAssertEqual(context.viewState.displayText, "#Foundation and Empire")
    }
    
    func testRoomAliasMentionMissingRoom() {
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
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertFalse(context.viewState.isUndefined)
        XCTAssertEqual(context.viewState.displayText, "#foundation-and-empire:matrix.org")
    }
    
    func testEventOnRoomIDMention() {
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
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertFalse(context.viewState.isUndefined)
        XCTAssertEqual(context.viewState.displayText, "💬 > #Foundation 🔭🪐🌌")
    }
    
    func testEventOnRoomIDMentionMissingRoom() {
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
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertFalse(context.viewState.isUndefined)
        XCTAssertEqual(context.viewState.displayText, "💬 > 1")
    }
    
    func testEventOnRoomAliasMention() {
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
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertFalse(context.viewState.isUndefined)
        XCTAssertEqual(context.viewState.displayText, "💬 > #Foundation and Empire")
    }
    
    func testEventOnRoomAliasMentionMissingRoom() {
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
        
        XCTAssertFalse(context.viewState.isOwnMention)
        XCTAssertFalse(context.viewState.isUndefined)
        XCTAssertEqual(context.viewState.displayText, "💬 > #foundation-and-empire:matrix.org")
    }
}
