//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import MatrixRustSDKMocks
import NotificationCenter
import Testing

@MainActor
final class NotificationManagerTests {
    var notificationManager: NotificationManager!
    private var notificationCenter: UserNotificationCenterMock!
    private let sessionsSubject = CurrentValueSubject<[UserSessionProtocol], Never>([])
    private let appSettings: AppSettings
    private var authorizationStatusWasGranted = false
    private var shouldDisplayInAppNotificationReturnValue = false
    private var handleInlineReplyDelegateCalled = false
    private var notificationTappedDelegateCalled = false
    private var registerForRemoteNotificationsDelegateCalled: (() -> Void)?
    
    init() {
        appSettings = AppSettings.volatile()
        notificationCenter = UserNotificationCenterMock()
        notificationCenter.requestAuthorizationOptionsReturnValue = true
        notificationCenter.authorizationStatusReturnValue = .authorized
        notificationCenter.notificationSettingsClosure = { await UNUserNotificationCenter.current().notificationSettings() }
        
        notificationManager = NotificationManager(notificationCenter: notificationCenter,
                                                  appSettings: appSettings,
                                                  sessionsPublisher: sessionsSubject.asCurrentValuePublisher())
        notificationManager.start()
    }
    
    isolated deinit {
        notificationCenter = nil
        notificationManager = nil
    }
    
    @Test
    func registeringHandsTheTokenToEveryAccount() async {
        let alice = NotificationServiceMock(.init())
        let bob = NotificationServiceMock(.init())
        sessionsSubject.send([makeSession(notificationService: alice), makeSession(notificationService: bob)])
        let deviceToken = Data("1234".utf8)
        
        await notificationManager.register(with: deviceToken)
        
        #expect(alice.registerDeviceTokenReceivedDeviceToken == deviceToken)
        #expect(bob.registerDeviceTokenReceivedDeviceToken == deviceToken)
    }
    
    @Test
    func anAccountGoingLiveAfterwardsGetsTheSavedToken() async {
        let deviceToken = Data("1234".utf8)
        await notificationManager.register(with: deviceToken)
        let alice = NotificationServiceMock(.init())
        
        await waitForConfirmation("The saved token should be registered", timeout: .seconds(10)) { confirm in
            alice.registerDeviceTokenClosure = { _ in confirm() }
            sessionsSubject.send([makeSession(notificationService: alice)])
        }
        
        #expect(alice.registerDeviceTokenReceivedDeviceToken == deviceToken)
    }
    
    @Test
    func aSessionReplacedAfterClearingTheCacheRegistersAgain() async {
        let oldService = NotificationServiceMock(.init())
        sessionsSubject.send([makeSession(notificationService: oldService)])
        await notificationManager.register(with: Data("1234".utf8))
        let newService = NotificationServiceMock(.init())
        
        await waitForConfirmation("The new session should register", timeout: .seconds(10)) { confirm in
            newService.registerDeviceTokenClosure = { _ in confirm() }
            sessionsSubject.send([makeSession(notificationService: newService)])
        }
        
        #expect(oldService.registerDeviceTokenCallsCount == 1)
    }
    
    @Test
    func launchingRegistersWhenAnAccountIsOnAndPermissionWasGiven() async {
        notificationManager.delegate = self
        
        await waitForConfirmation("registerForRemoteNotifications should be called", timeout: .seconds(10)) { confirm in
            registerForRemoteNotificationsDelegateCalled = { confirm() }
            sessionsSubject.send([makeSession(notificationService: NotificationServiceMock(.init()))])
        }
        
        #expect(authorizationStatusWasGranted)
    }
    
    @Test
    func launchingRegistersEvenWhenEveryAccountIsOff() async {
        notificationManager.delegate = self
        
        // So that accounts turned off delete any pusher left on their homeserver.
        await waitForConfirmation("registerForRemoteNotifications should be called", timeout: .seconds(10)) { confirm in
            registerForRemoteNotificationsDelegateCalled = { confirm() }
            sessionsSubject.send([makeSession(notificationService: NotificationServiceMock(.init(isEnabled: false)))])
        }
        
        #expect(authorizationStatusWasGranted)
    }
    
    @Test
    func theTokenIsForgottenOnceTheLastAccountIsGone() async throws {
        sessionsSubject.send([makeSession(notificationService: NotificationServiceMock(.init()))])
        await notificationManager.register(with: Data("1234".utf8))
        sessionsSubject.send([])
        let bob = NotificationServiceMock(.init())
        
        // The app unregisters from APNs when signing out of the last account, so the old token is dead.
        sessionsSubject.send([makeSession(notificationService: bob)])
        try await Task.sleep(for: .milliseconds(500))
        
        #expect(!bob.registerDeviceTokenCalled)
    }
    
    @Test
    func launchingNeverAsksForPermission() async throws {
        notificationCenter.authorizationStatusReturnValue = .notDetermined
        notificationManager.delegate = self
        
        sessionsSubject.send([makeSession(notificationService: NotificationServiceMock(.init()))])
        try await Task.sleep(for: .seconds(1))
        
        #expect(!notificationCenter.requestAuthorizationOptionsCalled)
        #expect(!authorizationStatusWasGranted)
    }
    
    @Test
    func turningAnAccountOnAsksForPermission() async {
        let isEnabledSubject = CurrentValueSubject<Bool, Never>(false)
        let alice = NotificationServiceMock(.init())
        alice.isEnabledPublisher = isEnabledSubject.asCurrentValuePublisher()
        sessionsSubject.send([makeSession(notificationService: alice)])
        
        await waitForConfirmation("requestAuthorization should be called", timeout: .seconds(10)) { confirm in
            notificationCenter.requestAuthorizationOptionsClosure = { _ in
                confirm()
                return true
            }
            isEnabledSubject.send(true)
        }
        
        #expect(notificationCenter.requestAuthorizationOptionsReceivedOptions == [.alert, .sound, .badge])
    }
    
    @Test
    func grantingPermissionRegistersForRemoteNotifications() async {
        notificationCenter.authorizationStatusReturnValue = .notDetermined
        notificationManager.delegate = self
        sessionsSubject.send([makeSession(notificationService: NotificationServiceMock(.init()))])
        
        await waitForConfirmation("registerForRemoteNotifications should be called", timeout: .seconds(10)) { confirm in
            registerForRemoteNotificationsDelegateCalled = { confirm() }
            notificationManager.requestAuthorization()
        }
        
        #expect(notificationCenter.requestAuthorizationOptionsReceivedOptions == [.alert, .sound, .badge])
    }
    
    @Test
    func requestingAuthorizationWithEveryAccountOffDoesNothing() async throws {
        sessionsSubject.send([makeSession(notificationService: NotificationServiceMock(.init(isEnabled: false)))])
        
        notificationManager.requestAuthorization()
        try await Task.sleep(for: .seconds(1))
        
        #expect(!notificationCenter.requestAuthorizationOptionsCalled)
    }
    
    @Test
    func appBadgeSumsEveryAccount() {
        sessionsSubject.send([makeSession(notificationService: NotificationServiceMock(.init(badgeCount: 3))),
                              makeSession(notificationService: NotificationServiceMock(.init(badgeCount: 2)))])
        
        #expect(appSettings.lastKnownBadgeCount == 5)
    }
    
    @Test
    func appBadgeFollowsAnAccountsCount() {
        let badgeCountSubject = CurrentValueSubject<Int, Never>(3)
        let alice = NotificationServiceMock(.init())
        alice.badgeCountPublisher = badgeCountSubject.asCurrentValuePublisher()
        sessionsSubject.send([makeSession(notificationService: alice)])
        
        badgeCountSubject.send(7)
        
        #expect(appSettings.lastKnownBadgeCount == 7)
    }
    
    @Test
    func appBadgeDropsARemovedAccount() {
        let alice = makeSession(notificationService: NotificationServiceMock(.init(badgeCount: 3)))
        let bob = makeSession(notificationService: NotificationServiceMock(.init(badgeCount: 2)))
        sessionsSubject.send([alice, bob])
        
        sessionsSubject.send([alice])
        
        #expect(appSettings.lastKnownBadgeCount == 3)
    }
    
    @Test
    func appBadgeIsLeftAloneWithoutAnAccount() {
        appSettings.lastKnownBadgeCount = 4
        
        sessionsSubject.send([])
        
        #expect(appSettings.lastKnownBadgeCount == 4)
        #expect(!notificationCenter.setBadgeCountCalled)
    }
    
    @Test
    func updatingTheAppBadge() async {
        await waitForConfirmation("The app badge should be set", timeout: .seconds(10)) { confirm in
            notificationCenter.setBadgeCountClosure = { _ in confirm() }
            sessionsSubject.send([makeSession(notificationService: NotificationServiceMock(.init(badgeCount: 7)))])
        }
        
        #expect(notificationCenter.setBadgeCountReceivedNewBadgeCount == 7)
    }
    
    @Test
    func whenShowLocalNotification_notificationRequestGetsAdded() async throws {
        await notificationManager.showLocalNotification(with: "Title", subtitle: "Subtitle")
        let request = try #require(notificationCenter.addReceivedRequest)
        #expect(request.content.title == "Title")
        #expect(request.content.subtitle == "Subtitle")
    }
    
    @Test
    func whenStart_notificationCategoriesAreSet() {
        let replyAction = UNTextInputNotificationAction(identifier: NotificationConstants.Action.inlineReply,
                                                        title: L10n.actionQuickReply,
                                                        options: [])
        let messageCategory = UNNotificationCategory(identifier: NotificationConstants.Category.message,
                                                     actions: [replyAction],
                                                     intentIdentifiers: [],
                                                     options: [])
        
        let inviteCategory = UNNotificationCategory(identifier: NotificationConstants.Category.invite,
                                                    actions: [],
                                                    intentIdentifiers: [],
                                                    options: [])
        #expect(notificationCenter.setNotificationCategoriesReceivedCategories == [messageCategory, inviteCategory])
    }
    
    @Test
    func whenStart_delegateIsSet() throws {
        let delegate = try #require(notificationCenter.delegate)
        #expect(delegate.isEqual(notificationManager))
    }
    
    @Test
    func whenWillPresentNotificationsDelegateNotSet_CorrectPresentationOptionsReturned() async throws {
        let archiver = MockCoder(requiringSecureCoding: false)
        let notification = try #require(UNNotification(coder: archiver))
        let options = await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        #expect(options == [.badge, .sound, .list, .banner])
    }
    
    @Test
    func whenWillPresentNotificationsDelegateSetAndNotificationsShoudNotBeDisplayed_CorrectPresentationOptionsReturned() async throws {
        shouldDisplayInAppNotificationReturnValue = false
        notificationManager.delegate = self
        
        let notification = try UNNotification.with(userInfo: [AnyHashable: Any]())
        let options = await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        #expect(options == [])
    }
    
    @Test
    func whenWillPresentNotificationsDelegateSetAndNotificationsShoudBeDisplayed_CorrectPresentationOptionsReturned() async throws {
        shouldDisplayInAppNotificationReturnValue = true
        notificationManager.delegate = self
        
        let notification = try UNNotification.with(userInfo: [AnyHashable: Any]())
        let options = await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), willPresent: notification)
        #expect(options == [.badge, .sound, .list, .banner])
    }
    
    @Test
    func whenNotificationCenterReceivedResponseInLineReply_delegateIsCalled() async throws {
        handleInlineReplyDelegateCalled = false
        notificationManager.delegate = self
        let response = try UNTextInputNotificationResponse.with(userInfo: [AnyHashable: Any](), actionIdentifier: NotificationConstants.Action.inlineReply)
        await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response)
        #expect(handleInlineReplyDelegateCalled)
    }
    
    @Test
    func whenNotificationCenterReceivedResponseWithActionIdentifier_delegateIsCalled() async throws {
        notificationTappedDelegateCalled = false
        notificationManager.delegate = self
        let response = try UNTextInputNotificationResponse.with(userInfo: [AnyHashable: Any](), actionIdentifier: UNNotificationDefaultActionIdentifier)
        await notificationManager.userNotificationCenter(UNUserNotificationCenter.current(), didReceive: response)
        #expect(notificationTappedDelegateCalled)
    }
    
    // MARK: - Helpers
    
    private func makeSession(notificationService: NotificationServiceMock) -> UserSessionMock {
        UserSessionMock(.init(notificationService: notificationService))
    }
}

extension NotificationManagerTests: @MainActor NotificationManagerDelegate {
    func registerForRemoteNotifications() {
        authorizationStatusWasGranted = true
        registerForRemoteNotificationsDelegateCalled?()
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
