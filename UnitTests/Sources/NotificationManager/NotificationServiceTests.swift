//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import SwiftUI
import Testing
import UserNotifications

@MainActor
final class NotificationServiceTests {
    private let clientProxy = ClientProxyMock(.init(userID: "@alice:example.com"))
    private let appSettings = AppSettings.volatile()
    private let userSettings: UserSettings
    private var actions: [NotificationServiceAction] = []
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        userSettings = appSettings.userSettings(for: "@alice:example.com")
    }
    
    // MARK: - Pushers
    
    @Test
    func registeringSetsThePusher() async throws {
        let service = makeService()
        let deviceToken = Data("1234".utf8)
        
        await service.register(deviceToken: deviceToken)
        
        let defaultPayload = APNSPayload(aps: APSInfo(mutableContent: 1,
                                                      alert: APSAlert(locKey: "Notification", locArgs: [])),
                                         pusherNotificationClientIdentifier: nil)
        let expectedConfiguration = try PusherConfiguration(identifiers: .init(pushkey: deviceToken.base64EncodedString(), appId: appSettings.pusherAppID),
                                                            kind: .http(data: .init(url: appSettings.pushGatewayNotifyEndpoint.absoluteString,
                                                                                    format: .eventIdOnly,
                                                                                    defaultPayload: defaultPayload.toJsonString())),
                                                            appDisplayName: "\(InfoPlistReader.main.bundleDisplayName) (iOS)",
                                                            deviceDisplayName: UIDevice.current.name,
                                                            profileTag: appSettings.pusherProfileTag,
                                                            lang: Bundle.app.preferredLocalizations.first ?? "en",
                                                            append: false)
        #expect(clientProxy.setPusherWithReceivedInvocations == [expectedConfiguration])
    }
    
    @Test
    func pushersAppendWithMultipleAccounts() async throws {
        appSettings.multiAccountEnabled = true
        let service = makeService()
        
        await service.register(deviceToken: Data())
        
        let configuration = try #require(clientProxy.setPusherWithReceivedInvocations.first)
        #expect(configuration.append)
    }
    
    @Test
    func registeringGeneratesAndSavesTheProfileTag() async {
        appSettings.pusherProfileTag = nil
        
        await makeService().register(deviceToken: Data())
        
        #expect(appSettings.pusherProfileTag != nil)
    }
    
    @Test
    func registeringKeepsTheSavedProfileTag() async {
        appSettings.pusherProfileTag = "12345"
        
        await makeService().register(deviceToken: Data())
        
        #expect(appSettings.pusherProfileTag == "12345")
    }
    
    @Test
    func registeringWhileTurnedOffDeletesThePusher() async throws {
        let service = makeService(isEnabled: false)
        let deviceToken = Data("1234".utf8)
        
        await service.register(deviceToken: deviceToken)
        
        #expect(!clientProxy.setPusherWithCalled)
        let identifiers = try #require(clientProxy.deletePusherWithReceivedIdentifiers)
        #expect(identifiers.pushkey == deviceToken.base64EncodedString())
        #expect(identifiers.appId == appSettings.pusherAppID)
    }
    
    // MARK: - Switch
    
    @Test
    func turningOffDeletesThePusher() async {
        let service = makeService()
        await service.register(deviceToken: Data("1234".utf8))
        
        await waitForConfirmation("The pusher should be deleted", timeout: .seconds(10)) { confirm in
            clientProxy.deletePusherWithClosure = { _ in confirm() }
            userSettings.account.enableNotifications = false
        }
        
        #expect(!service.isEnabled)
    }
    
    @Test
    func turningOnSetsThePusherAndAsksForPermission() async {
        let service = makeService(isEnabled: false)
        await service.register(deviceToken: Data("1234".utf8))
        
        await waitForConfirmation("The pusher should be set", timeout: .seconds(10)) { confirm in
            clientProxy.setPusherWithClosure = { _ in confirm() }
            userSettings.account.enableNotifications = true
        }
        
        #expect(service.isEnabled)
        #expect(isRequestAuthorization(actions.last))
    }
    
    @Test
    func turningOnBeforeRegisteringOnlyAsksForPermission() {
        let service = makeService(isEnabled: false)
        
        userSettings.account.enableNotifications = true
        
        #expect(service.isEnabled)
        #expect(!clientProxy.setPusherWithCalled)
        #expect(isRequestAuthorization(actions.last))
    }
    
    @Test
    func requestingAuthorizationAsksTheManager() {
        let service = makeService()
        
        service.requestAuthorization()
        
        #expect(isRequestAuthorization(actions.last))
    }
    
    // MARK: - Badge
    
    @Test
    func badgeCountStartsFromTheUnreadCount() {
        clientProxy.totalUnreadNotifications = 3
        
        let service = makeService()
        
        #expect(service.badgeCountPublisher.value == 3)
    }
    
    @Test
    func roomListChangesUpdateTheBadgeCount() async throws {
        let roomListSubject = CurrentValueSubject<[RoomSummary], Never>([])
        let roomSummaryProvider = RoomSummaryProviderMock(.init())
        roomSummaryProvider.roomListPublisher = roomListSubject.asCurrentValuePublisher()
        clientProxy.staticRoomSummaryProvider = roomSummaryProvider
        let service = makeService()
        
        let deferred = deferFulfillment(service.badgeCountPublisher) { $0 == 7 }
        clientProxy.totalUnreadNotifications = 7
        roomListSubject.send([])
        try await deferred.fulfill()
    }
    
    @Test
    func roomListChangesRepublishAnUnchangedBadgeCount() async throws {
        let roomListSubject = CurrentValueSubject<[RoomSummary], Never>([])
        let roomSummaryProvider = RoomSummaryProviderMock(.init())
        roomSummaryProvider.roomListPublisher = roomListSubject.asCurrentValuePublisher()
        clientProxy.staticRoomSummaryProvider = roomSummaryProvider
        clientProxy.totalUnreadNotifications = 3
        let service = makeService()
        
        // The extension bumps the app badge without the app knowing, so it needs resetting even when the count is the same.
        let deferred = deferFulfillment(service.badgeCountPublisher.dropFirst()) { $0 == 3 }
        roomListSubject.send([])
        try await deferred.fulfill()
    }
    
    // MARK: - Delivered notifications
    
    @Test
    func clearingARoomOnlyMatchesThatRoom() throws {
        let service = makeService()
        
        service.removeDeliveredMessageNotifications(for: "!room:example.com")
        
        let rule = try #require(removalRules.last)
        #expect(try rule(notification(roomID: "!room:example.com")))
        #expect(try !rule(notification(roomID: "!other:example.com")))
    }
    
    @Test
    func clearingFullyReadRoomsOnlyMatchesReadNotifications() throws {
        let room = RoomSummary(room: RoomSDKMock(), id: "!room:matrix.org", settingsMode: .allMessages,
                               hasUnreadMessages: false, hasUnreadMentions: false, hasUnreadNotifications: false)
        let lastMessageDate = try #require(room.lastMessageDate)
        let service = makeService()
        
        service.removeDeliveredNotificationsForFullyReadRooms([room])
        
        let rule = try #require(removalRules.last)
        // Delivered after the last message was sent, which is always the case for the last message's notification.
        let readNotification = try UNNotification.with(userInfo: [NotificationConstants.UserInfoKey.roomIdentifier: room.id,
                                                                  NotificationConstants.UserInfoKey.eventDate: lastMessageDate.addingTimeInterval(0.5)],
                                                       date: lastMessageDate.addingTimeInterval(5))
        let newerNotification = try UNNotification.with(userInfo: [NotificationConstants.UserInfoKey.roomIdentifier: room.id,
                                                                   NotificationConstants.UserInfoKey.eventDate: lastMessageDate.addingTimeInterval(1)],
                                                        date: lastMessageDate.addingTimeInterval(5))
        #expect(rule(readNotification))
        #expect(!rule(newerNotification))
        #expect(try !rule(notification(roomID: "!other:example.com")))
    }
    
    @Test
    func clearingWithoutFullyReadRoomsAsksNothing() {
        let room = RoomSummary(room: RoomSDKMock(), id: "!room:matrix.org", settingsMode: .allMessages,
                               hasUnreadMessages: true, hasUnreadMentions: false, hasUnreadNotifications: true)
        let service = makeService()
        
        service.removeDeliveredNotificationsForFullyReadRooms([room])
        
        #expect(removalRules.isEmpty)
    }
    
    @Test
    func tearingDownDeletesThePusherAndRemovesEveryNotification() async throws {
        let service = makeService()
        await service.register(deviceToken: Data())
        
        await service.tearDown()
        
        #expect(clientProxy.deletePusherWithCalled)
        let rule = try #require(removalRules.last)
        #expect(try rule(notification(roomID: "!any:example.com")))
    }
    
    // MARK: - Helpers
    
    private func makeService(isEnabled: Bool = true) -> NotificationService {
        userSettings.account.enableNotifications = isEnabled
        let service = NotificationService(clientProxy: clientProxy, userSettings: userSettings)
        service.actionsPublisher
            .sink { [weak self] action in
                self?.actions.append(action)
            }
            .store(in: &cancellables)
        return service
    }
    
    private func notification(roomID: String) throws -> UNNotification {
        try UNNotification.with(userInfo: [NotificationConstants.UserInfoKey.roomIdentifier: roomID])
    }
    
    private var removalRules: [(UNNotification) -> Bool] {
        actions.compactMap { action in
            guard case let .removeDeliveredNotifications(rule) = action else { return nil }
            return rule
        }
    }
    
    private func isRequestAuthorization(_ action: NotificationServiceAction?) -> Bool {
        guard case .requestAuthorization = action else { return false }
        return true
    }
}
