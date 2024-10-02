//
// Copyright 2023, 2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import MatrixRustSDK
import XCTest

@testable import ElementX

@MainActor
class NotificationSettingsScreenViewModelTests: XCTestCase {
    private var viewModel: NotificationSettingsScreenViewModelProtocol!
    private var context: NotificationSettingsScreenViewModelType.Context!
    private var appSettings: AppSettings!
    private var userNotificationCenter: UserNotificationCenterMock!
    private var notificationSettingsProxy: NotificationSettingsProxyMock!

    @MainActor override func setUpWithError() throws {
        AppSettings.resetAllSettings()

        userNotificationCenter = UserNotificationCenterMock()
        userNotificationCenter.authorizationStatusReturnValue = .authorized
        appSettings = AppSettings()
        notificationSettingsProxy = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .allMessages
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = true
        notificationSettingsProxy.isCallEnabledReturnValue = true
        
        viewModel = NotificationSettingsScreenViewModel(appSettings: appSettings,
                                                        userNotificationCenter: userNotificationCenter,
                                                        notificationSettingsProxy: notificationSettingsProxy,
                                                        isModallyPresented: false)
        context = viewModel.context
    }

    func testEnableNotifications() {
        appSettings.enableNotifications = false
        context.send(viewAction: .changedEnableNotifications)
        XCTAssertTrue(appSettings.enableNotifications)
    }

    func testDisableNotifications() {
        appSettings.enableNotifications = true
        context.send(viewAction: .changedEnableNotifications)
        XCTAssertFalse(appSettings.enableNotifications)
    }

    func testFetchSettings() async throws {
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = { isEncrypted, isOneToOne in
            switch (isEncrypted, isOneToOne) {
            case (_, true):
                return .allMessages
            case (_, _):
                return .mentionsAndKeywordsOnly
            }
        }
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }
        
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        
        try await deferred.fulfill()

        XCTAssertEqual(notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount, 4)
        XCTAssert(notificationSettingsProxy.isRoomMentionEnabledCalled)
        XCTAssert(notificationSettingsProxy.isCallEnabledCalled)

        XCTAssertEqual(context.viewState.settings?.groupChatsMode, .mentionsAndKeywordsOnly)
        XCTAssertEqual(context.viewState.settings?.directChatsMode, .allMessages)
        XCTAssertEqual(context.viewState.settings?.inconsistentSettings, [])
        XCTAssertNil(context.viewState.bindings.alertInfo)
    }

    func testInconsistentGroupChatsSettings() async throws {
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = { isEncrypted, isOneToOne in
            switch (isEncrypted, isOneToOne) {
            case (true, false):
                return .allMessages
            case (false, false):
                return .mentionsAndKeywordsOnly
            default:
                return .allMessages
            }
        }

        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }
        
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        
        try await deferred.fulfill()

        XCTAssertEqual(context.viewState.settings?.groupChatsMode, .allMessages)
        XCTAssertEqual(context.viewState.settings?.inconsistentSettings, [.init(chatType: .groupChat, isEncrypted: false)])
    }

    func testInconsistentDirectChatsSettings() async throws {
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = { isEncrypted, isOneToOne in
            switch (isEncrypted, isOneToOne) {
            case (true, true):
                return .allMessages
            case (false, true):
                return .mentionsAndKeywordsOnly
            default:
                return .allMessages
            }
        }

        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }

        notificationSettingsProxy.callbacks.send(.settingsDidChange)

        try await deferred.fulfill()

        XCTAssertEqual(context.viewState.settings?.directChatsMode, .allMessages)
        XCTAssertEqual(context.viewState.settings?.inconsistentSettings, [.init(chatType: .oneToOneChat, isEncrypted: false)])
    }

    func testFixInconsistentSettings() async throws {
        // Initialize with a configuration mismatch where encrypted one-to-one chats is `.allMessages` and unencrypted one-to-one chats is `.mentionsAndKeywordsOnly`
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = { isEncrypted, isOneToOne in
            switch (isEncrypted, isOneToOne) {
            case (true, true):
                return .allMessages
            case (false, true):
                return .mentionsAndKeywordsOnly
            default:
                return .allMessages
            }
        }

        var deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }
        
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        
        try await deferred.fulfill()

        XCTAssertEqual(context.viewState.settings?.directChatsMode, .allMessages)
        XCTAssertEqual(context.viewState.settings?.inconsistentSettings, [.init(chatType: .oneToOneChat, isEncrypted: false)])
        
        deferred = deferFulfillment(viewModel.context.$viewState, keyPath: \.fixingConfigurationMismatch, transitionValues: [false, true, false])
        
        context.send(viewAction: .fixConfigurationMismatchTapped)
        
        try await deferred.fulfill()

        // Ensure we only fix the invalid setting: unencrypted one-to-one chats should be set to `.allMessages` (to match encrypted one-to-one chats)
        XCTAssertEqual(notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount, 1)
        let callArguments = notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedArguments
        XCTAssertEqual(callArguments?.isEncrypted, false)
        XCTAssertEqual(callArguments?.isOneToOne, true)
        XCTAssertEqual(callArguments?.mode, .allMessages)
    }

    func testFixAllInconsistentSettings() async throws {
        // Initialize with a configuration mismatch where
        // - encrypted one-to-one chats is `.allMessages` and unencrypted one-to-one chats is `.mentionsAndKeywordsOnly`
        // - encrypted group chats is `.allMessages` and unencrypted group chats is `.mentionsAndKeywordsOnly`
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = { isEncrypted, isOneToOne in
            switch (isEncrypted, isOneToOne) {
            case (true, _):
                return .allMessages
            case (false, _):
                return .mentionsAndKeywordsOnly
            }
        }

        var deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }

        notificationSettingsProxy.callbacks.send(.settingsDidChange)

        try await deferred.fulfill()

        XCTAssertEqual(context.viewState.settings?.directChatsMode, .allMessages)
        XCTAssertEqual(context.viewState.settings?.inconsistentSettings, [.init(chatType: .groupChat, isEncrypted: false), .init(chatType: .oneToOneChat, isEncrypted: false)])

        deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.fixingConfigurationMismatch == true
        }
        
        context.send(viewAction: .fixConfigurationMismatchTapped)
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.fixingConfigurationMismatch == false
        }
        
        try await deferred.fulfill()

        // All problems should be fixed
        XCTAssertEqual(notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount, 2)
        let callArguments = notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations
        // Ensure we fix the invalid unencrypted group chats setting (it should be set to `.allMessages` to match encrypted group chats)
        XCTAssertEqual(callArguments[0].isEncrypted, false)
        XCTAssertEqual(callArguments[0].isOneToOne, false)
        XCTAssertEqual(callArguments[0].mode, .allMessages)
        // Ensure we fix the invalid unencrypted one-to-one chats setting (it should be set to `.allMessages` to match encrypted one-to-one chats)
        XCTAssertEqual(callArguments[1].isEncrypted, false)
        XCTAssertEqual(callArguments[1].isOneToOne, true)
        XCTAssertEqual(callArguments[1].mode, .allMessages)
    }

    func testToggleRoomMentionOff() async throws {
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = true
        
        let deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }
        
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        
        try await deferredState.fulfill()

        context.roomMentionsEnabled = false
        
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks) { callback in
            callback == .settingsDidChange
        }
        
        context.send(viewAction: .roomMentionChanged)
        
        try await deferred.fulfill()

        XCTAssert(notificationSettingsProxy.setRoomMentionEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setRoomMentionEnabledEnabledReceivedEnabled, false)
    }

    func testToggleRoomMentionOn() async throws {
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = false
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }
        
        viewModel.fetchInitialContent()
        try await deferredInitialFetch.fulfill()

        context.roomMentionsEnabled = true
        
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks) { callback in
            callback == .settingsDidChange
        }
        
        context.send(viewAction: .roomMentionChanged)
        
        try await deferred.fulfill()

        XCTAssert(notificationSettingsProxy.setRoomMentionEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setRoomMentionEnabledEnabledReceivedEnabled, true)
    }

    func testToggleRoomMentionFailure() async throws {
        notificationSettingsProxy.setRoomMentionEnabledEnabledThrowableError = NotificationSettingsError.Generic(msg: "error")
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = false
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.roomMentionsEnabled = true
        
        var deferred = deferFulfillment(context.$viewState) { state in
            state.applyingChange == true
        }
        
        context.send(viewAction: .roomMentionChanged)
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.$viewState) { state in
            state.applyingChange == false
        }
        
        try await deferred.fulfill()

        XCTAssertNotNil(context.alertInfo)
    }

    func testToggleCallsOff() async throws {
        notificationSettingsProxy.isCallEnabledReturnValue = true
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.callsEnabled = false
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks) { callback in
            callback == .settingsDidChange
        }
        
        context.send(viewAction: .callsChanged)
        
        try await deferred.fulfill()

        XCTAssert(notificationSettingsProxy.setCallEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setCallEnabledEnabledReceivedEnabled, false)
    }

    func testToggleCallsOn() async throws {
        notificationSettingsProxy.isCallEnabledReturnValue = false

        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.callsEnabled = true
        
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks) { callback in
            callback == .settingsDidChange
        }
        
        context.send(viewAction: .callsChanged)
        
        try await deferred.fulfill()

        XCTAssert(notificationSettingsProxy.setCallEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setCallEnabledEnabledReceivedEnabled, true)
    }

    func testToggleCallsFailure() async throws {
        notificationSettingsProxy.setCallEnabledEnabledThrowableError = NotificationSettingsError.Generic(msg: "error")
        notificationSettingsProxy.isCallEnabledReturnValue = false
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.callsEnabled = true
        
        var deferred = deferFulfillment(context.$viewState) { state in
            state.applyingChange == true
        }
        
        context.send(viewAction: .callsChanged)
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.$viewState) { state in
            state.applyingChange == false
        }
        
        try await deferred.fulfill()
        
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testToggleInvitationsOff() async throws {
        notificationSettingsProxy.isInviteForMeEnabledReturnValue = true
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.invitationsEnabled = false
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks) { callback in
            callback == .settingsDidChange
        }
        
        context.send(viewAction: .invitationsChanged)
        
        try await deferred.fulfill()

        XCTAssert(notificationSettingsProxy.setInviteForMeEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setInviteForMeEnabledEnabledReceivedEnabled, false)
    }

    func testToggleInvitationsOn() async throws {
        notificationSettingsProxy.isInviteForMeEnabledReturnValue = false
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.invitationsEnabled = true
        
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks) { callback in
            callback == .settingsDidChange
        }
        
        context.send(viewAction: .invitationsChanged)
        
        try await deferred.fulfill()

        XCTAssert(notificationSettingsProxy.setInviteForMeEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setInviteForMeEnabledEnabledReceivedEnabled, true)
    }

    func testToggleInvitesFailure() async throws {
        notificationSettingsProxy.setInviteForMeEnabledEnabledThrowableError = NotificationSettingsError.Generic(msg: "error")
        notificationSettingsProxy.isInviteForMeEnabledReturnValue = false
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState) { state in
            state.settings != nil
        }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.invitationsEnabled = true
        
        var deferred = deferFulfillment(context.$viewState) { state in
            state.applyingChange == true
        }
        
        context.send(viewAction: .invitationsChanged)
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.$viewState) { state in
            state.applyingChange == false
        }
        
        try await deferred.fulfill()
        
        XCTAssertNotNil(context.alertInfo)
    }
}
