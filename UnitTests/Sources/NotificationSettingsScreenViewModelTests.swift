//
// Copyright 2025 Element Creations Ltd.
// Copyright 2023-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import Testing

@MainActor @Suite
struct NotificationSettingsScreenViewModelTests {
    private var viewModel: NotificationSettingsScreenViewModelProtocol
    private var context: NotificationSettingsScreenViewModelType.Context
    private var appSettings: AppSettings
    private var userNotificationCenter: UserNotificationCenterMock
    private var notificationSettingsProxy: NotificationSettingsProxyMock

    init() throws {
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

    @Test
    func enableNotifications() {
        appSettings.enableNotifications = false
        context.send(viewAction: .changedEnableNotifications)
        #expect(appSettings.enableNotifications)
    }

    @Test
    func disableNotifications() {
        appSettings.enableNotifications = true
        context.send(viewAction: .changedEnableNotifications)
        #expect(!appSettings.enableNotifications)
    }

    @Test
    func fetchSettings() async throws {
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = { isEncrypted, isOneToOne in
            switch (isEncrypted, isOneToOne) {
            case (_, true):
                return .allMessages
            case (_, _):
                return .mentionsAndKeywordsOnly
            }
        }
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }
        
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        
        try await deferred.fulfill()

        #expect(notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount == 4)
        #expect(notificationSettingsProxy.isRoomMentionEnabledCalled)
        #expect(notificationSettingsProxy.isCallEnabledCalled)

        #expect(context.viewState.settings?.groupChatsMode == .mentionsAndKeywordsOnly)
        #expect(context.viewState.settings?.directChatsMode == .allMessages)
        #expect(context.viewState.settings?.inconsistentSettings == [])
        #expect(context.viewState.bindings.alertInfo == nil)
    }

    @Test
    func inconsistentGroupChatsSettings() async throws {
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

        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }
        
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        
        try await deferred.fulfill()

        #expect(context.viewState.settings?.groupChatsMode == .allMessages)
        #expect(context.viewState.settings?.inconsistentSettings == [.init(chatType: .groupChat, isEncrypted: false)])
    }

    @Test
    func inconsistentDirectChatsSettings() async throws {
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

        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }

        notificationSettingsProxy.callbacks.send(.settingsDidChange)

        try await deferred.fulfill()

        #expect(context.viewState.settings?.directChatsMode == .allMessages)
        #expect(context.viewState.settings?.inconsistentSettings == [.init(chatType: .oneToOneChat, isEncrypted: false)])
    }

    @Test
    func fixInconsistentSettings() async throws {
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

        let deferredSettings = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }
        
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        
        try await deferredSettings.fulfill()

        #expect(context.viewState.settings?.directChatsMode == .allMessages)
        #expect(context.viewState.settings?.inconsistentSettings == [.init(chatType: .oneToOneChat, isEncrypted: false)])
        
        let deferredMismatch = deferFulfillment(viewModel.context.observe(\.viewState.fixingConfigurationMismatch),
                                                transitionValues: [false, true, false])
        
        context.send(viewAction: .fixConfigurationMismatchTapped)
        
        try await deferredMismatch.fulfill()

        // Ensure we only fix the invalid setting: unencrypted one-to-one chats should be set to `.allMessages` (to match encrypted one-to-one chats)
        #expect(notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount == 1)
        let callArguments = notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedArguments
        #expect(callArguments?.isEncrypted == false)
        #expect(callArguments?.isOneToOne == true)
        #expect(callArguments?.mode == .allMessages)
    }

    @Test
    func fixAllInconsistentSettings() async throws {
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

        let deferredSettings = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }

        notificationSettingsProxy.callbacks.send(.settingsDidChange)

        try await deferredSettings.fulfill()

        #expect(context.viewState.settings?.directChatsMode == .allMessages)
        #expect(context.viewState.settings?.inconsistentSettings == [.init(chatType: .groupChat, isEncrypted: false), .init(chatType: .oneToOneChat, isEncrypted: false)])

        var deferredMismatch = deferFulfillment(viewModel.context.observe(\.viewState.fixingConfigurationMismatch)) { $0 }
        
        context.send(viewAction: .fixConfigurationMismatchTapped)
        
        try await deferredMismatch.fulfill()
        
        deferredMismatch = deferFulfillment(viewModel.context.observe(\.viewState.fixingConfigurationMismatch)) { !$0 }
        
        try await deferredMismatch.fulfill()

        // All problems should be fixed
        #expect(notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount == 2)
        let callArguments = notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations
        // Ensure we fix the invalid unencrypted group chats setting (it should be set to `.allMessages` to match encrypted group chats)
        #expect(callArguments[0].isEncrypted == false)
        #expect(callArguments[0].isOneToOne == false)
        #expect(callArguments[0].mode == .allMessages)
        // Ensure we fix the invalid unencrypted one-to-one chats setting (it should be set to `.allMessages` to match encrypted one-to-one chats)
        #expect(callArguments[1].isEncrypted == false)
        #expect(callArguments[1].isOneToOne == true)
        #expect(callArguments[1].mode == .allMessages)
    }

    @Test
    func toggleRoomMentionOff() async throws {
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = true
        
        let deferredState = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }
        
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        
        try await deferredState.fulfill()

        context.roomMentionsEnabled = false
        
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks) { callback in
            callback == .settingsDidChange
        }
        
        context.send(viewAction: .roomMentionChanged)
        
        try await deferred.fulfill()

        #expect(notificationSettingsProxy.setRoomMentionEnabledEnabledCalled)
        #expect(notificationSettingsProxy.setRoomMentionEnabledEnabledReceivedEnabled == false)
    }

    @Test
    func toggleRoomMentionOn() async throws {
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = false
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        try await deferredInitialFetch.fulfill()

        context.roomMentionsEnabled = true
        
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks) { callback in
            callback == .settingsDidChange
        }
        
        context.send(viewAction: .roomMentionChanged)
        
        try await deferred.fulfill()

        #expect(notificationSettingsProxy.setRoomMentionEnabledEnabledCalled)
        #expect(notificationSettingsProxy.setRoomMentionEnabledEnabledReceivedEnabled == true)
    }

    @Test
    func toggleRoomMentionFailure() async throws {
        notificationSettingsProxy.setRoomMentionEnabledEnabledThrowableError = NotificationSettingsError.Generic(msg: "error")
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = false
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.roomMentionsEnabled = true
        
        var deferred = deferFulfillment(context.observe(\.viewState.applyingChange)) { $0 }
        
        context.send(viewAction: .roomMentionChanged)
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.observe(\.viewState.applyingChange)) { !$0 }
        
        try await deferred.fulfill()

        #expect(context.alertInfo != nil)
    }

    @Test
    func toggleCallsOff() async throws {
        notificationSettingsProxy.isCallEnabledReturnValue = true
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.callsEnabled = false
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks) { callback in
            callback == .settingsDidChange
        }
        
        context.send(viewAction: .callsChanged)
        
        try await deferred.fulfill()

        #expect(notificationSettingsProxy.setCallEnabledEnabledCalled)
        #expect(notificationSettingsProxy.setCallEnabledEnabledReceivedEnabled == false)
    }

    @Test
    func toggleCallsOn() async throws {
        notificationSettingsProxy.isCallEnabledReturnValue = false

        let deferredInitialFetch = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.callsEnabled = true
        
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks) { callback in
            callback == .settingsDidChange
        }
        
        context.send(viewAction: .callsChanged)
        
        try await deferred.fulfill()

        #expect(notificationSettingsProxy.setCallEnabledEnabledCalled)
        #expect(notificationSettingsProxy.setCallEnabledEnabledReceivedEnabled == true)
    }

    @Test
    func toggleCallsFailure() async throws {
        notificationSettingsProxy.setCallEnabledEnabledThrowableError = NotificationSettingsError.Generic(msg: "error")
        notificationSettingsProxy.isCallEnabledReturnValue = false
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.callsEnabled = true
        
        var deferred = deferFulfillment(context.observe(\.viewState.applyingChange)) { $0 }
        
        context.send(viewAction: .callsChanged)
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.observe(\.viewState.applyingChange)) { !$0 }
        
        try await deferred.fulfill()
        
        #expect(context.alertInfo != nil)
    }
    
    @Test
    func toggleInvitationsOff() async throws {
        notificationSettingsProxy.isInviteForMeEnabledReturnValue = true
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.invitationsEnabled = false
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks) { callback in
            callback == .settingsDidChange
        }
        
        context.send(viewAction: .invitationsChanged)
        
        try await deferred.fulfill()

        #expect(notificationSettingsProxy.setInviteForMeEnabledEnabledCalled)
        #expect(notificationSettingsProxy.setInviteForMeEnabledEnabledReceivedEnabled == false)
    }

    @Test
    func toggleInvitationsOn() async throws {
        notificationSettingsProxy.isInviteForMeEnabledReturnValue = false
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.invitationsEnabled = true
        
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks) { callback in
            callback == .settingsDidChange
        }
        
        context.send(viewAction: .invitationsChanged)
        
        try await deferred.fulfill()

        #expect(notificationSettingsProxy.setInviteForMeEnabledEnabledCalled)
        #expect(notificationSettingsProxy.setInviteForMeEnabledEnabledReceivedEnabled == true)
    }

    @Test
    func toggleInvitesFailure() async throws {
        notificationSettingsProxy.setInviteForMeEnabledEnabledThrowableError = NotificationSettingsError.Generic(msg: "error")
        notificationSettingsProxy.isInviteForMeEnabledReturnValue = false
        
        let deferredInitialFetch = deferFulfillment(viewModel.context.observe(\.viewState.settings)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferredInitialFetch.fulfill()

        context.invitationsEnabled = true
        
        var deferred = deferFulfillment(context.observe(\.viewState.applyingChange)) { $0 }
        
        context.send(viewAction: .invitationsChanged)
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.observe(\.viewState.applyingChange)) { !$0 }
        
        try await deferred.fulfill()
        
        #expect(context.alertInfo != nil)
    }
}
