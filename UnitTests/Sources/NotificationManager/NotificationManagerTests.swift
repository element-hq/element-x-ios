//
// Copyright 2022 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest

import Combine
@testable import ElementX

final class NotificationManagerTests: XCTestCase {
    var notificationManager: NotificationManager!
    private let clientProxy = MockClientProxy(userIdentifier: "@test:user.net")
    private let notificationCenter = UserNotificationCenterSpy()
    private var authorizationStatusWasGranted = false
    private var shouldDisplayInAppNotificationReturnValue = false
    private var handleInlineReplyDelegateCalled = false
    private var notificationTappedDelegateCalled = false
    private let settings = ServiceLocator.shared.settings

    override func setUp() {
        notificationManager = NotificationManager(clientProxy: clientProxy, notificationCenter: notificationCenter)
    }
    
    func test_whenRegistered_pusherIsCalled() async {
        _ = await notificationManager.register(with: Data())
        XCTAssertTrue(clientProxy.setPusherCalled)
    }
    
    func test_whenRegisteredSuccess_completionSuccessIsCalled() async throws {
        let success = await notificationManager.register(with: Data())
        XCTAssertTrue(success)
    }
    
    func test_whenRegisteredAndPusherThrowsError_completionFalseIsCalled() async throws {
        enum TestError: Error {
            case someError
        }
        clientProxy.setPusherErrorToThrow = TestError.someError
        let success = await notificationManager.register(with: Data())
        XCTAssertFalse(success)
    }
    
    @MainActor
    func test_whenRegistered_pusherIsCalledWithCorrectValues() async throws {
        let pushkeyData = Data("1234".utf8)
        _ = await notificationManager.register(with: pushkeyData)
        XCTAssertEqual(clientProxy.setPusherPushkey, pushkeyData.base64EncodedString())
        XCTAssertEqual(clientProxy.setPusherAppId, settings?.pusherAppId)
        XCTAssertEqual(clientProxy.setPusherKind, .http)
        XCTAssertEqual(clientProxy.setPusherAppId, settings?.pusherAppId)
        XCTAssertEqual(clientProxy.setPusherAppDisplayName, "\(InfoPlistReader.target.bundleDisplayName) (iOS)")
        XCTAssertEqual(clientProxy.setPusherDeviceDisplayName, UIDevice.current.name)
        XCTAssertNotNil(clientProxy.setPusherProfileTag)
        XCTAssertEqual(clientProxy.setPusherLang, Bundle.preferredLanguages.first)
        XCTAssertEqual(clientProxy.setPusherUrl, settings?.pushGatewayBaseURL)
        XCTAssertEqual(clientProxy.setPusherFormat, .eventIdOnly)
        let defaultPayload: [AnyHashable: Any] = [
            "aps": [
                "mutable-content": 1,
                "alert": [
                    "loc-key": "Notification",
                    "loc-args": []
                ]
            ]
        ]
        let actualPayload = NSDictionary(dictionary: clientProxy.setPusherDefaultPayload ?? [:])
        XCTAssertTrue(actualPayload.isEqual(to: defaultPayload))
    }
    
    func test_whenRegisteredAndPusherTagNotSetInSettings_tagGeneratedAndSavedInSettings() async throws {
        settings?.pusherProfileTag = nil
        _ = await notificationManager.register(with: Data())
        XCTAssertNotNil(settings?.pusherProfileTag)
    }
    
    func test_whenRegisteredAndPusherTagIsSetInSettings_tagNotGenerated() async throws {
        settings?.pusherProfileTag = "12345"
        _ = await notificationManager.register(with: Data())
        XCTAssertEqual(settings?.pusherProfileTag, "12345")
    }
    
    func test_whenShowLocalNotification_notificationRequestGetsAdded() async throws {
        await notificationManager.showLocalNotification(with: "Title", subtitle: "Subtitle")
        let request = try XCTUnwrap(notificationCenter.addRequest)
        XCTAssertEqual(request.content.title, "Title")
        XCTAssertEqual(request.content.subtitle, "Subtitle")
    }
    
    func test_whenStart_notificationCategoriesAreSet() throws {
        notificationManager.start()
        let replyAction = UNTextInputNotificationAction(identifier: NotificationConstants.Action.inlineReply,
                                                        title: ElementL10n.actionQuickReply,
                                                        options: [])
        let replyCategory = UNNotificationCategory(identifier: NotificationConstants.Category.reply,
                                                   actions: [replyAction],
                                                   intentIdentifiers: [],
                                                   options: [])
        XCTAssertEqual(notificationCenter.notificationCategoriesValue, [replyCategory])
    }
    
    func test_whenStart_delegateIsSet() throws {
        notificationManager.start()
        let delegate = try XCTUnwrap(notificationCenter.delegate)
        XCTAssertTrue(delegate.isEqual(notificationManager))
    }
    
    func test_whenStart_requestAuthorizationCalledWithCorrectParams() async throws {
        notificationManager.start()
        await Task.yield()
        XCTAssertEqual(notificationCenter.requestAuthorizationOptions, [.alert, .sound, .badge])
    }
    
    func test_whenStartAndAuthorizationGranted_delegateCalled() async throws {
        authorizationStatusWasGranted = false
        notificationCenter.requestAuthorizationGrantedReturnValue = true
        notificationManager.delegate = self
        notificationManager.start()
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(authorizationStatusWasGranted)
    }
    
    func test_whenWillPresentNotificationsDelegateNotSet_CorrectPresentationOptionsReturned() async throws {
        notificationManager.start()
        let archiver = MockCoder(requiringSecureCoding: false)
        let notification = try XCTUnwrap(UNNotification(coder: archiver))
        let options = await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        XCTAssertEqual(options, [.badge, .sound, .list, .banner])
    }
    
    func test_whenWillPresentNotificationsDelegateSetAndNotificationsShoudNotBeDisplayed_CorrectPresentationOptionsReturned() async throws {
        shouldDisplayInAppNotificationReturnValue = false
        notificationManager.delegate = self
        notificationManager.start()
        let notification = try UNNotification.with(userInfo: [AnyHashable: Any]())
        let options = await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        XCTAssertEqual(options, [])
    }
    
    func test_whenWillPresentNotificationsDelegateSetAndNotificationsShoudBeDisplayed_CorrectPresentationOptionsReturned() async throws {
        shouldDisplayInAppNotificationReturnValue = true
        notificationManager.delegate = self
        notificationManager.start()
        let notification = try UNNotification.with(userInfo: [AnyHashable: Any]())
        let options = await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        XCTAssertEqual(options, [.badge, .sound, .list, .banner])
    }
    
    func test_whenNotificationCenterReceivedResponseInLineReply_delegateIsCalled() async throws {
        handleInlineReplyDelegateCalled = false
        notificationManager.delegate = self
        notificationManager.start()
        let response = try UNTextInputNotificationResponse.with(userInfo: [AnyHashable: Any](), actionIdentifier: NotificationConstants.Action.inlineReply)
        await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response)
        XCTAssertTrue(handleInlineReplyDelegateCalled)
    }
    
    func test_whenNotificationCenterReceivedResponseWithActionIdentifier_delegateIsCalled() async throws {
        notificationTappedDelegateCalled = false
        notificationManager.delegate = self
        notificationManager.start()
        let response = try UNTextInputNotificationResponse.with(userInfo: [AnyHashable: Any](), actionIdentifier: UNNotificationDefaultActionIdentifier)
        await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response)
        XCTAssertTrue(notificationTappedDelegateCalled)
    }
}

extension NotificationManagerTests: NotificationManagerDelegate {
    func authorizationStatusUpdated(_ service: ElementX.NotificationManagerProtocol, granted: Bool) {
        authorizationStatusWasGranted = granted
    }
    
    func shouldDisplayInAppNotification(_ service: ElementX.NotificationManagerProtocol, content: UNNotificationContent) -> Bool {
        shouldDisplayInAppNotificationReturnValue
    }
    
    func notificationTapped(_ service: ElementX.NotificationManagerProtocol, content: UNNotificationContent) async {
        notificationTappedDelegateCalled = true
    }
    
    func handleInlineReply(_ service: ElementX.NotificationManagerProtocol, content: UNNotificationContent, replyText: String) async {
        handleInlineReplyDelegateCalled = true
    }
}
