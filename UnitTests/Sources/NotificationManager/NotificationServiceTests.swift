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
    
    @Test("Registering sets the pusher")
    func register() async throws {
        let service = makeService()
        let deviceToken = Data("1234".utf8)
        
        await service.register(.init(deviceToken: deviceToken, appendsPusher: false))
        
        let defaultPayload = APNSPayload(aps: APSInfo(mutableContent: 1,
                                                      alert: APSAlert(locKey: "Notification", locArgs: [])),
                                         pusherNotificationClientIdentifier: nil)
        let expectedConfiguration = try PusherConfiguration(identifiers: .init(pushkey: deviceToken.base64EncodedString(), appId: appSettings.pusherAppID),
                                                            kind: .http(data: .init(url: appSettings.pushGatewayNotifyEndpoint.absoluteString,
                                                                                    format: .eventIdOnly,
                                                                                    defaultPayload: defaultPayload.toJsonString())),
                                                            appDisplayName: "\(InfoPlistReader.main.bundleDisplayName) (iOS)",
                                                            deviceDisplayName: UIDevice.current.name,
                                                            profileTag: nil,
                                                            lang: Bundle.app.preferredLocalizations.first ?? "en",
                                                            append: false)
        #expect(clientProxy.setPusherWithReceivedInvocations == [expectedConfiguration])
    }
    
    @Test("Registering appends the pusher when the registration parameters ask for it")
    func registerAppendingPusher() async throws {
        let service = makeService()
        
        await service.register(.init(deviceToken: Data(), appendsPusher: true))
        
        let configuration = try #require(clientProxy.setPusherWithReceivedInvocations.first)
        #expect(configuration.append)
    }
    
    @Test("Updating the registration parameters changes whether the pusher is appended the next time it's set")
    func updateRegistrationParameters() async throws {
        let service = makeService(isEnabled: false)
        await service.register(.init(deviceToken: Data(), appendsPusher: false))
        
        service.updateRegistrationParameters(appendsPusher: true)
        await waitForConfirmation("The pusher should be set", timeout: .seconds(10)) { confirm in
            clientProxy.setPusherWithClosure = { _ in confirm() }
            userSettings.account.enableNotifications = true
        }
        
        let configuration = try #require(clientProxy.setPusherWithReceivedInvocations.first)
        #expect(configuration.append)
    }
    
    @Test("Registering while notifications are off deletes the pusher")
    func registerWithNotificationsDisabled() async throws {
        let service = makeService(isEnabled: false)
        let deviceToken = Data("1234".utf8)
        
        await service.register(.init(deviceToken: deviceToken, appendsPusher: false))
        
        #expect(!clientProxy.setPusherWithCalled)
        let identifiers = try #require(clientProxy.deletePusherWithReceivedIdentifiers)
        #expect(identifiers.pushkey == deviceToken.base64EncodedString())
        #expect(identifiers.appId == appSettings.pusherAppID)
    }
    
    // MARK: - Switch
    
    @Test("Turning notifications off deletes the pusher")
    func disableNotifications() async {
        let service = makeService()
        await service.register(.init(deviceToken: Data("1234".utf8), appendsPusher: false))
        
        await waitForConfirmation("The pusher should be deleted", timeout: .seconds(10)) { confirm in
            clientProxy.deletePusherWithClosure = { _ in confirm() }
            userSettings.account.enableNotifications = false
        }
        
        #expect(!service.isEnabled)
    }
    
    @Test("Turning notifications on sets the pusher and asks for permission")
    func enableNotifications() async {
        let service = makeService(isEnabled: false)
        await service.register(.init(deviceToken: Data("1234".utf8), appendsPusher: false))
        
        await waitForConfirmation("The pusher should be set", timeout: .seconds(10)) { confirm in
            clientProxy.setPusherWithClosure = { _ in confirm() }
            userSettings.account.enableNotifications = true
        }
        
        #expect(service.isEnabled)
        #expect(isRequestAuthorization(actions.last))
    }
    
    @Test("Turning notifications on before registering only asks for permission")
    func enableNotificationsBeforeRegistering() {
        let service = makeService(isEnabled: false)
        
        userSettings.account.enableNotifications = true
        
        #expect(service.isEnabled)
        #expect(!clientProxy.setPusherWithCalled)
        #expect(isRequestAuthorization(actions.last))
    }
    
    @Test("Requesting authorization asks the manager")
    func requestAuthorization() {
        let service = makeService()
        
        service.requestAuthorization()
        
        #expect(isRequestAuthorization(actions.last))
    }
    
    // MARK: - Badge
    
    @Test("The badge count starts from the unread count")
    func initialBadgeCount() {
        clientProxy.totalUnreadNotifications = 3
        
        let service = makeService()
        
        #expect(service.badgeCountPublisher.value == 3)
    }
    
    @Test("Room list changes update the badge count")
    func badgeCountUpdates() async throws {
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
    
    @Test("Room list changes republish an unchanged badge count")
    func unchangedBadgeCount() async throws {
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
    
    @Test("Clearing a room's notifications only matches that room")
    func removeRoomNotifications() throws {
        let service = makeService()
        
        service.removeDeliveredMessageNotifications(for: "!room:example.com")
        
        let rule = try #require(removalRules.last)
        #expect(try rule(notification(roomID: "!room:example.com")))
        #expect(try !rule(notification(roomID: "!other:example.com")))
    }
    
    @Test("Clearing fully read rooms only matches the notifications that were read")
    func removeFullyReadRoomNotifications() throws {
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
    
    @Test("Clearing without any fully read rooms asks nothing of the manager")
    func removeWithoutFullyReadRooms() {
        let room = RoomSummary(room: RoomSDKMock(), id: "!room:matrix.org", settingsMode: .allMessages,
                               hasUnreadMessages: true, hasUnreadMentions: false, hasUnreadNotifications: true)
        let service = makeService()
        
        service.removeDeliveredNotificationsForFullyReadRooms([room])
        
        #expect(removalRules.isEmpty)
    }
    
    @Test("Tearing down deletes the pusher and removes every notification")
    func tearDown() async throws {
        let service = makeService()
        await service.register(.init(deviceToken: Data(), appendsPusher: false))
        
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
