//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import NotificationCenter
import XCTest

@testable import ElementX

@MainActor
final class NotificationManagerTests: XCTestCase {
    var notificationManager: NotificationManager!
    private let clientProxy = ClientProxyMock(.init(userID: "@test:user.net"))
    private lazy var mockUserSession = UserSessionMock(.init(clientProxy: clientProxy))
    private var notificationCenter: UserNotificationCenterMock!
    private var authorizationStatusWasGranted = false
    private var shouldDisplayInAppNotificationReturnValue = false
    private var handleInlineReplyDelegateCalled = false
    private var notificationTappedDelegateCalled = false
    private var registerForRemoteNotificationsDelegateCalled: (() -> Void)?
    
    private var appSettings: AppSettings { ServiceLocator.shared.settings }

    override func setUp() {
        AppSettings.resetAllSettings()
        notificationCenter = UserNotificationCenterMock()
        notificationCenter.requestAuthorizationOptionsReturnValue = true
        notificationCenter.authorizationStatusReturnValue = .authorized
        
        notificationManager = NotificationManager(notificationCenter: notificationCenter, appSettings: appSettings)
        notificationManager.start()
        notificationManager.setUserSession(mockUserSession)
    }
    
    override func tearDown() {
        notificationCenter = nil
        notificationManager = nil
    }
    
    func test_whenRegistered_pusherIsCalled() async {
        _ = await notificationManager.register(with: Data())
        
        XCTAssertTrue(clientProxy.setPusherWithCalled)
    }
    
    func test_whenRegisteredSuccess_completionSuccessIsCalled() async throws {
        let success = await notificationManager.register(with: Data())
        XCTAssertTrue(success)
    }

    func test_whenRegisteredAndPusherThrowsError_completionFalseIsCalled() async throws {
        enum TestError: Error {
            case someError
        }
        
        clientProxy.setPusherWithThrowableError = TestError.someError
        let success = await notificationManager.register(with: Data())
        XCTAssertFalse(success)
    }

    func test_whenRegistered_pusherIsCalledWithCorrectValues() async throws {
        let pushkeyData = Data("1234".utf8)
        _ = await notificationManager.register(with: pushkeyData)
        
        guard let configuration = clientProxy.setPusherWithReceivedInvocations.first else {
            XCTFail("Invalid pusher configuration sent")
            return
        }
        
        XCTAssertEqual(configuration.identifiers.pushkey, pushkeyData.base64EncodedString())
        XCTAssertEqual(configuration.identifiers.appId, appSettings.pusherAppId)
        XCTAssertEqual(configuration.appDisplayName, "\(InfoPlistReader.main.bundleDisplayName) (iOS)")
        XCTAssertEqual(configuration.deviceDisplayName, UIDevice.current.name)
        XCTAssertNotNil(configuration.profileTag)
        XCTAssertEqual(configuration.lang, Bundle.app.preferredLocalizations.first)
        guard case let .http(data) = configuration.kind else {
            XCTFail("Http kind expected")
            return
        }
        XCTAssertEqual(data.url, appSettings.pushGatewayBaseURL.absoluteString)
        XCTAssertEqual(data.format, .eventIdOnly)
        let defaultPayload = APNSPayload(aps: APSInfo(mutableContent: 1,
                                                      alert: APSAlert(locKey: "Notification",
                                                                      locArgs: [])),
                                         pusherNotificationClientIdentifier: nil)
        XCTAssertEqual(data.defaultPayload, try defaultPayload.toJsonString())
    }

    func test_whenRegisteredAndPusherTagNotSetInSettings_tagGeneratedAndSavedInSettings() async throws {
        appSettings.pusherProfileTag = nil
        _ = await notificationManager.register(with: Data())
        XCTAssertNotNil(appSettings.pusherProfileTag)
    }

    func test_whenRegisteredAndPusherTagIsSetInSettings_tagNotGenerated() async throws {
        appSettings.pusherProfileTag = "12345"
        _ = await notificationManager.register(with: Data())
        XCTAssertEqual(appSettings.pusherProfileTag, "12345")
    }

    func test_whenShowLocalNotification_notificationRequestGetsAdded() async throws {
        await notificationManager.showLocalNotification(with: "Title", subtitle: "Subtitle")
        let request = try XCTUnwrap(notificationCenter.addReceivedRequest)
        XCTAssertEqual(request.content.title, "Title")
        XCTAssertEqual(request.content.subtitle, "Subtitle")
    }

    func test_whenStart_notificationCategoriesAreSet() throws {
        //        let replyAction = UNTextInputNotificationAction(identifier: NotificationConstants.Action.inlineReply,
        //                                                        title: L10n.actionQuickReply,
        //                                                        options: [])
        let messageCategory = UNNotificationCategory(identifier: NotificationConstants.Category.message,
                                                     actions: [],
                                                     intentIdentifiers: [],
                                                     options: [])
        let inviteCategory = UNNotificationCategory(identifier: NotificationConstants.Category.invite,
                                                    actions: [],
                                                    intentIdentifiers: [],
                                                    options: [])
        XCTAssertEqual(notificationCenter.setNotificationCategoriesReceivedCategories, [messageCategory, inviteCategory])
    }

    func test_whenStart_delegateIsSet() throws {
        let delegate = try XCTUnwrap(notificationCenter.delegate)
        XCTAssertTrue(delegate.isEqual(notificationManager))
    }

    func test_whenStart_requestAuthorizationCalledWithCorrectParams() async throws {
        let expectation = expectation(description: "requestAuthorization should be called")
        notificationCenter.requestAuthorizationOptionsClosure = { _ in
            expectation.fulfill()
            return true
        }
        notificationManager.requestAuthorization()
        await fulfillment(of: [expectation])
        XCTAssertEqual(notificationCenter.requestAuthorizationOptionsReceivedOptions, [.alert, .sound, .badge])
    }

    func test_whenStartAndAuthorizationGranted_delegateCalled() async throws {
        authorizationStatusWasGranted = false
        notificationManager.delegate = self
        let expectation: XCTestExpectation = expectation(description: "registerForRemoteNotifications delegate function should be called")
        expectation.assertForOverFulfill = false
        registerForRemoteNotificationsDelegateCalled = {
            expectation.fulfill()
        }
        notificationManager.requestAuthorization()
        await fulfillment(of: [expectation])
        XCTAssertTrue(authorizationStatusWasGranted)
    }
    
    func test_whenStartAndAuthorizedAndNotificationDisabled_registerForRemoteNotificationsNotCalled() async throws {
        appSettings.enableNotifications = false
        notificationCenter.authorizationStatusReturnValue = .authorized
        notificationManager.delegate = self
        
        notificationManager.setUserSession(UserSessionMock(.init(clientProxy: ClientProxyMock(.init()))))
        try await Task.sleep(for: .seconds(1))
        
        XCTAssertFalse(authorizationStatusWasGranted)
    }
    
    func test_whenStartAndAuthorized_registerForRemoteNotificationsCalled() async throws {
        appSettings.enableNotifications = true
        notificationCenter.authorizationStatusReturnValue = .authorized
        notificationManager.delegate = self
        
        let expectation: XCTestExpectation = expectation(description: "registerForRemoteNotifications delegate function should be called")
        expectation.assertForOverFulfill = false
        registerForRemoteNotificationsDelegateCalled = {
            expectation.fulfill()
        }
        
        notificationManager.setUserSession(UserSessionMock(.init(clientProxy: ClientProxyMock(.init()))))
        await fulfillment(of: [expectation])
        
        XCTAssertTrue(authorizationStatusWasGranted)
    }

    func test_whenWillPresentNotificationsDelegateNotSet_CorrectPresentationOptionsReturned() async throws {
        let archiver = MockCoder(requiringSecureCoding: false)
        let notification = try XCTUnwrap(UNNotification(coder: archiver))
        let options = await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        XCTAssertEqual(options, [.badge, .sound, .list, .banner])
    }

    func test_whenWillPresentNotificationsDelegateSetAndNotificationsShoudNotBeDisplayed_CorrectPresentationOptionsReturned() async throws {
        shouldDisplayInAppNotificationReturnValue = false
        notificationManager.delegate = self

        let notification = try UNNotification.with(userInfo: [AnyHashable: Any]())
        let options = await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        XCTAssertEqual(options, [])
    }

    func test_whenWillPresentNotificationsDelegateSetAndNotificationsShoudBeDisplayed_CorrectPresentationOptionsReturned() async throws {
        shouldDisplayInAppNotificationReturnValue = true
        notificationManager.delegate = self

        let notification = try UNNotification.with(userInfo: [AnyHashable: Any]())
        let options = await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        XCTAssertEqual(options, [.badge, .sound, .list, .banner])
    }

    func test_whenNotificationCenterReceivedResponseInLineReply_delegateIsCalled() async throws {
        handleInlineReplyDelegateCalled = false
        notificationManager.delegate = self
        let response = try UNTextInputNotificationResponse.with(userInfo: [AnyHashable: Any](), actionIdentifier: NotificationConstants.Action.inlineReply)
        await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response)
        XCTAssertTrue(handleInlineReplyDelegateCalled)
    }

    func test_whenNotificationCenterReceivedResponseWithActionIdentifier_delegateIsCalled() async throws {
        notificationTappedDelegateCalled = false
        notificationManager.delegate = self
        let response = try UNTextInputNotificationResponse.with(userInfo: [AnyHashable: Any](), actionIdentifier: UNNotificationDefaultActionIdentifier)
        await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response)
        XCTAssertTrue(notificationTappedDelegateCalled)
    }
}

extension NotificationManagerTests: NotificationManagerDelegate {
    func registerForRemoteNotifications() {
        authorizationStatusWasGranted = true
        registerForRemoteNotificationsDelegateCalled?()
    }
    
    func unregisterForRemoteNotifications() {
        authorizationStatusWasGranted = false
    }
    
    func shouldDisplayInAppNotification(content: UNNotificationContent) -> Bool {
        shouldDisplayInAppNotificationReturnValue
    }
    
    func notificationTapped(content: UNNotificationContent) async {
        notificationTappedDelegateCalled = true
    }
    
    func handleInlineReply(_ service: ElementX.NotificationManagerProtocol, content: UNNotificationContent, replyText: String) async {
        handleInlineReplyDelegateCalled = true
    }
}
