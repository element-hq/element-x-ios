//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import MatrixRustSDKMocks
import SwiftUI
import Testing
import UserNotifications

struct NotificationServiceTests {
    private let clientProxy = ClientProxyMock(.init(userID: "@alice:example.com"))
    private let appSettings = AppSettings.volatile()
    private let userSettings: UserSettings
    private let notificationCenter = UserNotificationCenterMock()
    
    init() {
        userSettings = appSettings.userSettings(for: "@alice:example.com")
        notificationCenter.deliveredNotificationsReturnValue = []
    }
    
    @Test
    func registeringSetsThePusher() async throws {
        let service = makeService()
        let deviceToken = Data("1234".utf8)
        
        await service.register(deviceToken: deviceToken)
        
        let configuration = try #require(clientProxy.setPusherWithReceivedInvocations.first)
        #expect(configuration.identifiers.pushkey == deviceToken.base64EncodedString())
        #expect(configuration.identifiers.appId == appSettings.pusherAppID)
        #expect(configuration.appDisplayName == "\(InfoPlistReader.main.bundleDisplayName) (iOS)")
        #expect(configuration.deviceDisplayName == UIDevice.current.name)
        #expect(configuration.profileTag != nil)
        #expect(configuration.lang == Bundle.app.preferredLocalizations.first)
        #expect(!configuration.append)
        guard case let .http(data) = configuration.kind else {
            Issue.record("Http kind expected")
            return
        }
        #expect(data.url == appSettings.pushGatewayNotifyEndpoint.absoluteString)
        #expect(data.format == .eventIdOnly)
        let defaultPayload = APNSPayload(aps: APSInfo(mutableContent: 1,
                                                      alert: APSAlert(locKey: "Notification",
                                                                      locArgs: [])),
                                         pusherNotificationClientIdentifier: nil)
        #expect(try data.defaultPayload == defaultPayload.toJsonString())
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
    
    @Test
    func turningOffDeletesThePusherAndSavesTheSwitch() async {
        let service = makeService()
        await service.register(deviceToken: Data())
        
        let result = await service.setEnabled(false)
        
        #expect(throws: Never.self) { try result.get() }
        #expect(clientProxy.deletePusherWithCalled)
        #expect(!userSettings.account.enableNotifications)
        #expect(!service.isEnabledPublisher.value)
    }
    
    @Test
    func turningOnFailsAndKeepsTheSwitchWhenThePusherCantBeSet() async {
        let service = makeService(isEnabled: false)
        await service.register(deviceToken: Data())
        clientProxy.setPusherWithThrowableError = TestError.someError
        
        let result = await service.setEnabled(true)
        
        #expect(throws: NotificationServiceError.failedUpdatingPusher) { try result.get() }
        #expect(!userSettings.account.enableNotifications)
        #expect(!service.isEnabledPublisher.value)
    }
    
    @Test
    func turningOnBeforeRegisteringOnlySavesTheSwitch() async {
        let service = makeService(isEnabled: false)
        
        let result = await service.setEnabled(true)
        
        #expect(throws: Never.self) { try result.get() }
        #expect(!clientProxy.setPusherWithCalled)
        #expect(userSettings.account.enableNotifications)
        #expect(service.isEnabledPublisher.value)
    }
    
    @Test
    func badgeCountStartsFromTheUnreadCount() {
        clientProxy.totalUnreadNotifications = 3
        
        let service = makeService()
        
        #expect(service.badgeCountPublisher.value == 3)
    }
    
    @Test
    func clearingARoomOnlyRemovesThisAccountsNotifications() async throws {
        notificationCenter.deliveredNotificationsReturnValue = try [notification("alice", roomID: "!shared:example.com", receiverID: "@alice:example.com"),
                                                                    notification("bob", roomID: "!shared:example.com", receiverID: "@bob:example.com"),
                                                                    notification("other room", roomID: "!other:example.com", receiverID: "@alice:example.com")]
        let service = makeService()
        
        await service.removeDeliveredMessageNotifications(for: "!shared:example.com")
        
        #expect(notificationCenter.removeDeliveredNotificationsWithIdentifiersReceivedIdentifiers == ["alice"])
    }
    
    @Test
    func clearingFullyReadRoomsOnlyRemovesThisAccountsNotifications() async throws {
        let room = RoomSummary(room: RoomSDKMock(), id: "!room:matrix.org", settingsMode: .allMessages,
                               hasUnreadMessages: false, hasUnreadMentions: false, hasUnreadNotifications: false)
        let lastMessageDate = try #require(room.lastMessageDate)
        
        // Delivered after the last message was sent, which is always the case for the last message's notification.
        let readNotification = try UNNotification.with(userInfo: [NotificationConstants.UserInfoKey.roomIdentifier: room.id,
                                                                  NotificationConstants.UserInfoKey.receiverIdentifier: "@alice:example.com",
                                                                  NotificationConstants.UserInfoKey.eventDate: lastMessageDate.addingTimeInterval(0.5)],
                                                       identifier: "read",
                                                       date: lastMessageDate.addingTimeInterval(5))
        let newerNotification = try UNNotification.with(userInfo: [NotificationConstants.UserInfoKey.roomIdentifier: room.id,
                                                                   NotificationConstants.UserInfoKey.receiverIdentifier: "@alice:example.com",
                                                                   NotificationConstants.UserInfoKey.eventDate: lastMessageDate.addingTimeInterval(1)],
                                                        identifier: "newer",
                                                        date: lastMessageDate.addingTimeInterval(5))
        let otherAccountNotification = try UNNotification.with(userInfo: [NotificationConstants.UserInfoKey.roomIdentifier: room.id,
                                                                          NotificationConstants.UserInfoKey.receiverIdentifier: "@bob:example.com",
                                                                          NotificationConstants.UserInfoKey.eventDate: lastMessageDate.addingTimeInterval(0.5)],
                                                               identifier: "bob",
                                                               date: lastMessageDate.addingTimeInterval(5))
        notificationCenter.deliveredNotificationsReturnValue = [readNotification, newerNotification, otherAccountNotification]
        let service = makeService()
        
        await service.removeDeliveredNotificationsForFullyReadRooms([room])
        
        #expect(notificationCenter.removeDeliveredNotificationsWithIdentifiersReceivedIdentifiers == ["read"])
    }
    
    @Test
    func tearingDownDeletesThePusherAndThisAccountsNotifications() async throws {
        notificationCenter.deliveredNotificationsReturnValue = try [notification("alice", roomID: "!shared:example.com", receiverID: "@alice:example.com"),
                                                                    notification("bob", roomID: "!shared:example.com", receiverID: "@bob:example.com")]
        let service = makeService()
        await service.register(deviceToken: Data())
        
        await service.tearDown()
        
        #expect(clientProxy.deletePusherWithCalled)
        #expect(notificationCenter.removeDeliveredNotificationsWithIdentifiersReceivedIdentifiers == ["alice"])
    }
    
    // MARK: - Helpers
    
    private enum TestError: Error {
        case someError
    }
    
    private func makeService(isEnabled: Bool = true) -> NotificationService {
        userSettings.account.enableNotifications = isEnabled
        return NotificationService(clientProxy: clientProxy, userSettings: userSettings, notificationCenter: notificationCenter)
    }
    
    private func notification(_ identifier: String, roomID: String, receiverID: String) throws -> UNNotification {
        try UNNotification.with(userInfo: [NotificationConstants.UserInfoKey.roomIdentifier: roomID,
                                           NotificationConstants.UserInfoKey.receiverIdentifier: receiverID],
                                identifier: identifier)
    }
}
