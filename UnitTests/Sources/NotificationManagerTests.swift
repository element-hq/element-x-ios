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
        XCTAssertEqual(clientProxySpy.setPusherAppId, BuildSettings.pusherAppId)
        XCTAssertEqual(clientProxySpy.setPusherKind, .http)
        XCTAssertEqual(clientProxySpy.setPusherAppId, BuildSettings.pusherAppId)
        XCTAssertEqual(clientProxySpy.setPusherAppDisplayName, "\(InfoPlistReader.target.bundleDisplayName) (iOS)")
        XCTAssertEqual(clientProxySpy.setPusherDeviceDisplayName, UIDevice.current.name)
        XCTAssertNotNil(clientProxySpy.setPusherProfileTag)
        XCTAssertEqual(clientProxySpy.setPusherLang, Bundle.preferredLanguages.first)
        XCTAssertEqual(clientProxySpy.setPusherUrl, BuildSettings.pushGatewayBaseURL.absoluteString)
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
        ElementSettings.shared.pusherProfileTag = nil
        sut.register(with: Data(), completion: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 0.5)
        XCTAssertNotNil(ElementSettings.shared.pusherProfileTag)
    }
    
    func test_whenRegisteredAndPusherTagIsSetInSettings_tagNotGenerated() throws {
        let expectation = expectation(description: "Callback happened")
        ElementSettings.shared.pusherProfileTag = "12345"
        sut.register(with: Data(), completion: { _ in
            expectation.fulfill()
        })
        waitForExpectations(timeout: 0.5)
        XCTAssertEqual(ElementSettings.shared.pusherProfileTag, "12345")
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
}

extension NotificationManagerTests: NotificationManagerDelegate {
    func authorizationStatusUpdated(_ service: ElementX.NotificationManagerProtocol, granted: Bool) {
        authorizationStatusWasGranted = granted
    }
    
    func shouldDisplayInAppNotification(_ service: ElementX.NotificationManagerProtocol, content: UNNotificationContent) -> Bool {
        shouldDisplayInAppNotificationReturnValue
    }
    
    func notificationTapped(_ service: ElementX.NotificationManagerProtocol, content: UNNotificationContent) async { }
    
    func handleInlineReply(_ service: ElementX.NotificationManagerProtocol, content: UNNotificationContent, replyText: String) async { }
}

// MARK: - Helpers

class MockCoder: NSKeyedArchiver {
    override func decodeObject(forKey key: String) -> Any { "" }
}

class UserNotificationCenterSpy: UserNotificationCenterProtocol {
    weak var delegate: UNUserNotificationCenterDelegate?
    
    var addRequest: UNNotificationRequest?
    func add(_ request: UNNotificationRequest, withCompletionHandler completionHandler: ((Error?) -> Void)?) {
        addRequest = request
        completionHandler?(nil)
    }
    
    var requestAuthorizationOptions: UNAuthorizationOptions?
    var requestAuthorizationGrantedReturnValue = false
    func requestAuthorization(options: UNAuthorizationOptions, completionHandler: @escaping (Bool, Error?) -> Void) {
        requestAuthorizationOptions = options
        completionHandler(requestAuthorizationGrantedReturnValue, nil)
    }
    
    var notificationCategoriesValue: Set<UNNotificationCategory>?
    func setNotificationCategories(_ categories: Set<UNNotificationCategory>) {
        notificationCategoriesValue = categories
    }
}

private class ClientProxySpy: ClientProxyProtocol {
    let callbacks = PassthroughSubject<ClientProxyCallback, Never>()
    
    var userIdentifier = ""
    
    var isSoftLogout = false
    
    var deviceId: String? = ""
    
    var homeserver = ""
    
    var restorationToken: ElementX.RestorationToken?
    
    var roomSummaryProvider: ElementX.RoomSummaryProviderProtocol?
    
    internal init() { }
    
    func startSync() { }
    
    func stopSync() { }
    
    func restartSync() { }
    
    func roomForIdentifier(_ identifier: String) async -> ElementX.RoomProxyProtocol? {
        nil
    }
    
    func loadUserDisplayName() async -> Result<String, ElementX.ClientProxyError> {
        .failure(.failedLoadingMedia)
    }
    
    func loadUserAvatarURLString() async -> Result<String, ElementX.ClientProxyError> {
        .failure(.failedLoadingMedia)
    }
    
    func accountDataEvent<Content>(type: String) async -> Result<Content?, ClientProxyError> where Content: Decodable {
        .failure(.failedLoadingMedia)
    }
    
    func setAccountData<Content>(content: Content, type: String) async -> Result<Void, ClientProxyError> where Content: Encodable {
        .failure(.failedLoadingMedia)
    }
    
    func sessionVerificationControllerProxy() async -> Result<ElementX.SessionVerificationControllerProxyProtocol, ClientProxyError> {
        .failure(.failedLoadingMedia)
    }
    
    func logout() async { }
    
    var setPusherCalled = false
    var setPusherErrorToThrow: Error?
    var setPusherPushkey: String?
    var setPusherKind: PusherKind?
    var setPusherAppId: String?
    var setPusherAppDisplayName: String?
    var setPusherDeviceDisplayName: String?
    var setPusherProfileTag: String?
    var setPusherLang: String?
    var setPusherUrl: String?
    var setPusherFormat: PushFormat?
    var setPusherDefaultPayload: [AnyHashable: Any]?
    
    // swiftlint:disable:next function_parameter_count
    func setPusher(pushkey: String, kind: PusherKind?, appId: String, appDisplayName: String, deviceDisplayName: String, profileTag: String?, lang: String, url: String?, format: PushFormat?, defaultPayload: [AnyHashable: Any]?) async throws {
        if let setPusherErrorToThrow {
            throw setPusherErrorToThrow
        }
        setPusherCalled = true
        setPusherPushkey = pushkey
        setPusherKind = kind
        setPusherAppId = appId
        setPusherAppDisplayName = appDisplayName
        setPusherDeviceDisplayName = deviceDisplayName
        setPusherProfileTag = profileTag
        setPusherLang = lang
        setPusherUrl = url
        setPusherFormat = format
        setPusherDefaultPayload = defaultPayload
    }
    
    func mediaSourceForURLString(_ urlString: String) -> ElementX.MediaSourceProxy {
        MediaSourceProxy(urlString: "")
    }
    
    func loadMediaContentForSource(_ source: ElementX.MediaSourceProxy) async throws -> Data {
        Data()
    }
    
    func loadMediaThumbnailForSource(_ source: ElementX.MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        Data()
    }
}
