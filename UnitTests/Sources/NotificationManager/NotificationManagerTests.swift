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
    var sut: NotificationManager!
    private let clientProxySpy = ClientProxySpy()
    private let notificationCenter = UserNotificationCenterSpy()
    private var authorizationStatusWasGranted = false
    private var shouldDisplayInAppNotificationReturnValue = false
    private var handleInlineReplyDelegateCalled = false
    private var notificationTappedDelegateCalled = false
    private let settings = ServiceLocator.shared.settings

    override func setUp() {
        sut = NotificationManager(clientProxy: clientProxySpy, notificationCenter: notificationCenter)
    }
    
    func test_whenRegistered_pusherIsCalled() throws {
        let expectation = expectation(description: "Callback happened")
        sut.register(with: Data(), completion: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 0.5)
        XCTAssertTrue(clientProxySpy.setPusherCalled)
    }
    
    func test_whenRegisteredSuccess_completionSuccessIsCalled() throws {
        let expectation = expectation(description: "Callback happened")
        var success = false
        sut.register(with: Data(), completion: { s in
            success = s
            expectation.fulfill()
        })
        waitForExpectations(timeout: 0.5)
        XCTAssertTrue(success)
    }
    
    func test_whenRegisteredAndPusherThrowsError_completionFalseIsCalled() throws {
        let expectation = expectation(description: "Callback happened")
        var success = true
        enum TestError: Error {
            case someError
        }
        clientProxySpy.setPusherErrorToThrow = TestError.someError
        sut.register(with: Data(), completion: { s in
            success = s
            expectation.fulfill()
        })
        waitForExpectations(timeout: 0.5)
        XCTAssertFalse(success)
    }
    
    func test_whenRegistered_pusherIsCalledWithCorrectValues() throws {
        let expectation = expectation(description: "Callback happened")
        let pushkeyData = Data("1234".utf8)
        sut.register(with: pushkeyData, completion: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 0.5)
        XCTAssertEqual(clientProxySpy.setPusherPushkey, pushkeyData.base64EncodedString())
        XCTAssertEqual(clientProxySpy.setPusherAppId, settings?.pusherAppId)
        XCTAssertEqual(clientProxySpy.setPusherKind, .http)
        XCTAssertEqual(clientProxySpy.setPusherAppId, settings?.pusherAppId)
        XCTAssertEqual(clientProxySpy.setPusherAppDisplayName, "\(InfoPlistReader.target.bundleDisplayName) (iOS)")
        XCTAssertEqual(clientProxySpy.setPusherDeviceDisplayName, UIDevice.current.name)
        XCTAssertNotNil(clientProxySpy.setPusherProfileTag)
        XCTAssertEqual(clientProxySpy.setPusherLang, Bundle.preferredLanguages.first)
        XCTAssertEqual(clientProxySpy.setPusherUrl, settings?.pushGatewayBaseURL.absoluteString)
        XCTAssertEqual(clientProxySpy.setPusherFormat, .eventIdOnly)
        let defaultPayload: [AnyHashable: Any] = [
            "aps": [
                "mutable-content": 1,
                "alert": [
                    "loc-key": "Notification",
                    "loc-args": []
                ]
            ]
        ]
        let actualPayload = NSDictionary(dictionary: clientProxySpy.setPusherDefaultPayload ?? [:])
        XCTAssertTrue(actualPayload.isEqual(to: defaultPayload))
    }
    
    func test_whenRegisteredAndPusherTagNotSetInSettings_tagGeneratedAndSavedInSettings() throws {
        let expectation = expectation(description: "Callback happened")
        settings?.pusherProfileTag = nil
        sut.register(with: Data(), completion: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 0.5)
        XCTAssertNotNil(settings?.pusherProfileTag)
    }
    
    func test_whenRegisteredAndPusherTagIsSetInSettings_tagNotGenerated() throws {
        let expectation = expectation(description: "Callback happened")
        settings?.pusherProfileTag = "12345"
        sut.register(with: Data(), completion: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 0.5)
        XCTAssertEqual(settings?.pusherProfileTag, "12345")
    }
    
    func test_whenShowLocalNotification_notificationRequestGetsAdded() throws {
        sut.showLocalNotification(with: "Title", subtitle: "Subtitle")
        let request = try XCTUnwrap(notificationCenter.addRequest)
        XCTAssertEqual(request.content.title, "Title")
        XCTAssertEqual(request.content.subtitle, "Subtitle")
    }
    
    func test_whenStart_notificationCategoriesAreSet() throws {
        sut.start()
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
        sut.start()
        let delegate = try XCTUnwrap(notificationCenter.delegate)
        XCTAssertTrue(delegate.isEqual(sut))
    }
    
    func test_whenStart_requestAuthorizationCalledWithCorrectParams() throws {
        sut.start()
        XCTAssertEqual(notificationCenter.requestAuthorizationOptions, [.alert, .sound, .badge])
    }
    
    func test_whenStartAndAuthorizationGranted_delegateCalled() throws {
        authorizationStatusWasGranted = false
        notificationCenter.requestAuthorizationGrantedReturnValue = true
        sut.delegate = self
        sut.start()
        let expectation = expectation(description: "Wait for main thread")
        DispatchQueue.main.async {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 1, handler: nil)
        XCTAssertTrue(authorizationStatusWasGranted)
    }
    
    func test_whenWillPresentNotificationsDelegateNotSet_CorrectPresentationOptionsReturned() async throws {
        sut.start()
        let archiver = MockCoder(requiringSecureCoding: false)
        let notification = try XCTUnwrap(UNNotification(coder: archiver))
        let options = await sut.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        XCTAssertEqual(options, [.badge, .sound, .list, .banner])
    }
    
    func test_whenWillPresentNotificationsDelegateSetAndNotificationsShoudNotBeDisplayed_CorrectPresentationOptionsReturned() async throws {
        shouldDisplayInAppNotificationReturnValue = false
        sut.delegate = self
        sut.start()
        let notification = try UNNotification.with(userInfo: [AnyHashable: Any]())
        let options = await sut.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        XCTAssertEqual(options, [])
    }
    
    func test_whenWillPresentNotificationsDelegateSetAndNotificationsShoudBeDisplayed_CorrectPresentationOptionsReturned() async throws {
        shouldDisplayInAppNotificationReturnValue = true
        sut.delegate = self
        sut.start()
        let notification = try UNNotification.with(userInfo: [AnyHashable: Any]())
        let options = await sut.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        XCTAssertEqual(options, [.badge, .sound, .list, .banner])
    }
    
    func test_whenNotificationCenterReceivedResponseInLineReply_delegateIsCalled() async throws {
        handleInlineReplyDelegateCalled = false
        sut.delegate = self
        sut.start()
        let response = try UNTextInputNotificationResponse.with(userInfo: [AnyHashable: Any](), actionIdentifier: NotificationConstants.Action.inlineReply)
        await sut.userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response)
        XCTAssertTrue(handleInlineReplyDelegateCalled)
    }
    
    func test_whenNotificationCenterReceivedResponseWithActionIdentifier_delegateIsCalled() async throws {
        notificationTappedDelegateCalled = false
        sut.delegate = self
        sut.start()
        let response = try UNTextInputNotificationResponse.with(userInfo: [AnyHashable: Any](), actionIdentifier: UNNotificationDefaultActionIdentifier)
        await sut.userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response)
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
