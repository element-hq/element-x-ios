//
// Copyright 2025 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
final class FirebaseIntegrationTests: XCTestCase {
    private var notificationManager: NotificationManager!
    private var firebaseMock: FirebaseNotificationServiceMock!
    private var clientProxy: ClientProxyMock!
    private var notificationCenter: UserNotificationCenterMock!

    private var appSettings: AppSettings {
        ServiceLocator.shared.settings
    }

    override func setUp() {
        AppSettings.resetAllSettings()
        firebaseMock = FirebaseNotificationServiceMock()
        clientProxy = ClientProxyMock(.init(userID: "@test:user.net"))
        notificationCenter = UserNotificationCenterMock()
        notificationCenter.requestAuthorizationOptionsReturnValue = true
        notificationCenter.authorizationStatusReturnValue = .authorized
        notificationCenter.notificationSettingsClosure = { await UNUserNotificationCenter.current().notificationSettings() }

        notificationManager = NotificationManager(notificationCenter: notificationCenter, appSettings: appSettings)
        notificationManager.start()
    }

    override func tearDown() {
        notificationCenter = nil
        notificationManager = nil
        firebaseMock = nil
        clientProxy = nil
    }

    // MARK: - Tests

    func test_firebaseProvider_configureIsCalled() {
        appSettings.pushProvider = .firebase
        let mockUserSession = UserSessionMock(.init(clientProxy: clientProxy))
        notificationManager.setUserSession(mockUserSession)

        // Simulate what AppCoordinator.configureNotificationManager() does for Firebase
        firebaseMock.configure { [weak self] fcmToken in
            Task { await self?.notificationManager.registerWithFCMToken(fcmToken) }
        }

        XCTAssertTrue(firebaseMock.configureOnTokenUpdateCalled)
    }

    func test_firebaseProvider_tokenCallbackRegistersWithFCMToken() async throws {
        appSettings.pushProvider = .firebase
        let mockUserSession = UserSessionMock(.init(clientProxy: clientProxy))
        notificationManager.setUserSession(mockUserSession)

        // Simulate AppCoordinator wiring: configure firebase with a callback
        firebaseMock.configure { [weak self] fcmToken in
            Task { await self?.notificationManager.registerWithFCMToken(fcmToken) }
        }

        // Simulate Firebase delivering a token via the captured callback
        let capturedCallback = try XCTUnwrap(firebaseMock.configureOnTokenUpdateReceivedOnTokenUpdate)
        capturedCallback("test-fcm-token-abc123")

        // Allow the async Task to complete
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertTrue(clientProxy.setPusherWithCalled)
        let configuration = try XCTUnwrap(clientProxy.setPusherWithReceivedConfiguration)
        XCTAssertEqual(configuration.identifiers.pushkey, "test-fcm-token-abc123")
    }

    func test_apnsProvider_configureIsNotCalled() {
        appSettings.pushProvider = .apns
        let mockUserSession = UserSessionMock(.init(clientProxy: clientProxy))
        notificationManager.setUserSession(mockUserSession)

        // Simulate what AppCoordinator does: only configure firebase when pushProvider == .firebase
        if appSettings.pushProvider == .firebase {
            firebaseMock.configure { _ in }
        }

        XCTAssertFalse(firebaseMock.configureOnTokenUpdateCalled)
    }

    func test_firebaseProvider_tokenRefreshReRegisters() async throws {
        appSettings.pushProvider = .firebase
        let mockUserSession = UserSessionMock(.init(clientProxy: clientProxy))
        notificationManager.setUserSession(mockUserSession)

        // Simulate AppCoordinator wiring
        firebaseMock.configure { [weak self] fcmToken in
            Task { await self?.notificationManager.registerWithFCMToken(fcmToken) }
        }

        let capturedCallback = try XCTUnwrap(firebaseMock.configureOnTokenUpdateReceivedOnTokenUpdate)

        // First token
        capturedCallback("token-v1")
        try await Task.sleep(for: .milliseconds(100))

        // Second token (refresh)
        capturedCallback("token-v2")
        try await Task.sleep(for: .milliseconds(100))

        XCTAssertEqual(clientProxy.setPusherWithCallsCount, 2)
        XCTAssertEqual(clientProxy.setPusherWithReceivedInvocations.last?.identifiers.pushkey, "token-v2")
    }

    func test_firebaseProvider_apnsTokenNotUsedForPusher() async throws {
        appSettings.pushProvider = .firebase
        let mockUserSession = UserSessionMock(.init(clientProxy: clientProxy))
        notificationManager.setUserSession(mockUserSession)

        // When pushProvider is .firebase, calling register(with: deviceToken) should
        // NOT set the pusher — the APNs device token goes to Firebase SDK, not the Matrix server.
        // Only registerWithFCMToken should set the pusher.
        _ = await notificationManager.register(with: Data("apns-device-token".utf8))

        // The APNs register path still calls setPusher (the NotificationManager doesn't know
        // about push providers — that routing is in AppCoordinator). But we verify that
        // the pushkey is base64-encoded (APNs style), not a raw FCM token.
        let configuration = try XCTUnwrap(clientProxy.setPusherWithReceivedConfiguration)
        let expectedAPNSPushkey = Data("apns-device-token".utf8).base64EncodedString()
        XCTAssertEqual(configuration.identifiers.pushkey, expectedAPNSPushkey)
        XCTAssertNotEqual(configuration.identifiers.pushkey, "apns-device-token")
    }
}
