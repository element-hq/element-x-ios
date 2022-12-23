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
    private let clientProxyMock = ClientProxyMock()
    private let notificationCenter = UserNotificationCenterSpy()
    private var authorizationStatusWasGranted = false
    private var shouldDisplayInAppNotificationReturnValue = false
    private var handleInlineReplyDelegateCalled = false
    private var notificationTappedDelegateCalled = false
    private let settings = ServiceLocator.shared.settings

    override func setUp() {
        sut = NotificationManager(clientProxy: clientProxyMock, notificationCenter: notificationCenter)
    }
    
    func test_whenRegistered_pusherIsCalled() async {
        _ = await sut.register(with: Data())
        XCTAssertTrue(clientProxyMock.setPusherCalled)
    }
    
    func test_whenRegisteredSuccess_completionSuccessIsCalled() async throws {
        let success = await sut.register(with: Data())
        XCTAssertTrue(success)
    }
    
    func test_whenRegisteredAndPusherThrowsError_completionFalseIsCalled() async throws {
        enum TestError: Error {
            case someError
        }
        clientProxyMock.setPusherErrorToThrow = TestError.someError
        let success = await sut.register(with: Data())
        XCTAssertFalse(success)
    }
    
    @MainActor
    func test_whenRegistered_pusherIsCalledWithCorrectValues() async throws {
        let pushkeyData = Data("1234".utf8)
        _ = await sut.register(with: pushkeyData)
        XCTAssertEqual(clientProxyMock.setPusherPushkey, pushkeyData.base64EncodedString())
        XCTAssertEqual(clientProxyMock.setPusherAppId, settings?.pusherAppId)
        XCTAssertEqual(clientProxyMock.setPusherKind, .http)
        XCTAssertEqual(clientProxyMock.setPusherAppId, settings?.pusherAppId)
        XCTAssertEqual(clientProxyMock.setPusherAppDisplayName, "\(InfoPlistReader.target.bundleDisplayName) (iOS)")
        XCTAssertEqual(clientProxyMock.setPusherDeviceDisplayName, UIDevice.current.name)
        XCTAssertNotNil(clientProxyMock.setPusherProfileTag)
        XCTAssertEqual(clientProxyMock.setPusherLang, Bundle.preferredLanguages.first)
        XCTAssertEqual(clientProxyMock.setPusherUrl, settings?.pushGatewayBaseURL.absoluteString)
        XCTAssertEqual(clientProxyMock.setPusherFormat, .eventIdOnly)
        let defaultPayload: [AnyHashable: Any] = [
            "aps": [
                "mutable-content": 1,
                "alert": [
                    "loc-key": "Notification",
                    "loc-args": []
                ]
            ]
        ]
        let actualPayload = NSDictionary(dictionary: clientProxyMock.setPusherDefaultPayload ?? [:])
        XCTAssertTrue(actualPayload.isEqual(to: defaultPayload))
    }
    
    func test_whenRegisteredAndPusherTagNotSetInSettings_tagGeneratedAndSavedInSettings() async throws {
        settings?.pusherProfileTag = nil
        _ = await sut.register(with: Data())
        XCTAssertNotNil(settings?.pusherProfileTag)
    }
    
    func test_whenRegisteredAndPusherTagIsSetInSettings_tagNotGenerated() async throws {
        settings?.pusherProfileTag = "12345"
        _ = await sut.register(with: Data())
        XCTAssertEqual(settings?.pusherProfileTag, "12345")
    }
    
    func test_whenShowLocalNotification_notificationRequestGetsAdded() async throws {
        await sut.showLocalNotification(with: "Title", subtitle: "Subtitle")
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
    
    func test_whenStart_requestAuthorizationCalledWithCorrectParams() async throws {
        sut.start()
        await Task.yield()
        XCTAssertEqual(notificationCenter.requestAuthorizationOptions, [.alert, .sound, .badge])
    }
    
    func test_whenStartAndAuthorizationGranted_delegateCalled() async throws {
        authorizationStatusWasGranted = false
        notificationCenter.requestAuthorizationGrantedReturnValue = true
        sut.delegate = self
        sut.start()
        try await Task.sleep(for: .milliseconds(100))
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
