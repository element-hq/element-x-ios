//
// Copyright 2023 New Vector Ltd
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
        AppSettings.reset()
        
        userNotificationCenter = UserNotificationCenterMock()
        userNotificationCenter.authorizationStatusReturnValue = .authorized
        appSettings = AppSettings()
        notificationSettingsProxy = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
        notificationSettingsProxy.getDefaultNotificationRoomModeIsEncryptedActiveMembersCountReturnValue = .allMessages
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = true
        notificationSettingsProxy.isCallEnabledReturnValue = true
        
        viewModel = NotificationSettingsScreenViewModel(appSettings: appSettings,
                                                        userNotificationCenter: userNotificationCenter,
                                                        notificationSettingsProxy: notificationSettingsProxy)
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
        notificationSettingsProxy.getDefaultNotificationRoomModeIsEncryptedActiveMembersCountClosure = { isEncrypted, activeMembersCount in
            switch (isEncrypted, activeMembersCount) {
            case (_, 2):
                return .allMessages
            case (_, _):
                return .mentionsAndKeywordsOnly
            }
        }
        let deferredDirectChatsSettings = deferFulfillment(viewModel.context.$viewState
            .collect(6)
            .first())
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        try await deferredDirectChatsSettings.fulfill()
        
        XCTAssertEqual(notificationSettingsProxy.getDefaultNotificationRoomModeIsEncryptedActiveMembersCountCallsCount, 4)
        XCTAssert(notificationSettingsProxy.isRoomMentionEnabledCalled)
        XCTAssert(notificationSettingsProxy.isCallEnabledCalled)
        
        XCTAssert(isState(context.viewState.groupChatNotificationSettingsState, loadedWithValue: .mentionsAndKeywordsOnly))
        XCTAssert(isState(context.viewState.directChatNotificationSettingsState, loadedWithValue: .allMessages))
        XCTAssertFalse(context.viewState.inconsistentGroupChatsSettings)
        XCTAssertFalse(context.viewState.inconsistentDirectChatsSettings)
        XCTAssertNil(context.viewState.bindings.alertInfo)
    }
    
    func isState(_ state: NotificationSettingsScreenModeState, loadedWithValue value: RoomNotificationModeProxy) -> Bool {
        switch state {
        case .loaded(let mode):
            return mode == value
        default:
            return false
        }
    }
    
    func testInconsistentGroupChatsSettings() async throws {
        notificationSettingsProxy.getDefaultNotificationRoomModeIsEncryptedActiveMembersCountClosure = { isEncrypted, activeMembersCount in
            switch (isEncrypted, activeMembersCount) {
            case (true, 3):
                return .allMessages
            case (false, 3):
                return .mentionsAndKeywordsOnly
            default:
                return .allMessages
            }
        }
                
        let deferred = deferFulfillment(viewModel.context.$viewState.map(\.inconsistentGroupChatsSettings)
            .removeDuplicates()
            .collect(2)
            .first())
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        let states = try await deferred.fulfill()
        
        XCTAssertEqual(states, [false, true])
        XCTAssert(isState(context.viewState.groupChatNotificationSettingsState, loadedWithValue: .allMessages))
        XCTAssert(context.viewState.inconsistentGroupChatsSettings)
        XCTAssertFalse(context.viewState.inconsistentDirectChatsSettings)
    }
    
    func testInconsistentDirectChatsSettings() async throws {
        notificationSettingsProxy.getDefaultNotificationRoomModeIsEncryptedActiveMembersCountClosure = { isEncrypted, activeMembersCount in
            switch (isEncrypted, activeMembersCount) {
            case (true, 2):
                return .allMessages
            case (false, 2):
                return .mentionsAndKeywordsOnly
            default:
                return .allMessages
            }
        }
                
        let deferred = deferFulfillment(viewModel.context.$viewState.map(\.inconsistentDirectChatsSettings)
            .removeDuplicates()
            .collect(2)
            .first())
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        let states = try await deferred.fulfill()
        
        XCTAssertEqual(states, [false, true])
        XCTAssert(isState(context.viewState.directChatNotificationSettingsState, loadedWithValue: .allMessages))
        XCTAssertFalse(context.viewState.inconsistentGroupChatsSettings)
        XCTAssert(context.viewState.inconsistentDirectChatsSettings)
    }
    
    func testToggleRoomMentionOff() async throws {
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = true
        context.enableRoomMention = false
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks
            .first(where: { $0 == .settingsDidChange }))
        context.send(viewAction: .processToggleRoomMention)
        try await deferred.fulfill()
        
        XCTAssert(notificationSettingsProxy.setRoomMentionEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setRoomMentionEnabledEnabledReceivedEnabled, false)
    }
    
    func testToggleRoomMentionOn() async throws {
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = false
        context.enableRoomMention = true
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks
            .first(where: { $0 == .settingsDidChange }))
        context.send(viewAction: .processToggleRoomMention)
        try await deferred.fulfill()
        
        XCTAssert(notificationSettingsProxy.setRoomMentionEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setRoomMentionEnabledEnabledReceivedEnabled, true)
    }
    
    func testToggleRoomMentionFailure() async throws {
        notificationSettingsProxy.setRoomMentionEnabledEnabledThrowableError = NotificationSettingsError.Generic(message: "error")
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = false
        context.enableRoomMention = true
        let deferred = deferFulfillment(context.$viewState.map(\.applyingChange)
            .removeDuplicates()
            .collect(3)
            .first())
        context.send(viewAction: .processToggleRoomMention)
        let states = try await deferred.fulfill()
        
        XCTAssertEqual(states, [false, true, false])
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testToggleCallsOff() async throws {
        notificationSettingsProxy.isCallEnabledReturnValue = true
        context.enableCalls = false
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks
            .first(where: { $0 == .settingsDidChange }))
        context.send(viewAction: .processToggleCalls)
        try await deferred.fulfill()
        
        XCTAssert(notificationSettingsProxy.setCallEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setCallEnabledEnabledReceivedEnabled, false)
    }
    
    func testToggleCallsOn() async throws {
        notificationSettingsProxy.isCallEnabledReturnValue = false
        context.enableCalls = true
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks
            .first(where: { $0 == .settingsDidChange }))
        context.send(viewAction: .processToggleCalls)
        try await deferred.fulfill()

        XCTAssert(notificationSettingsProxy.setCallEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setCallEnabledEnabledReceivedEnabled, true)
    }
    
    func testToggleCallsFailure() async throws {
        notificationSettingsProxy.setCallEnabledEnabledThrowableError = NotificationSettingsError.Generic(message: "error")
        notificationSettingsProxy.isCallEnabledReturnValue = false
        context.enableCalls = true
        let deferred = deferFulfillment(context.$viewState.map(\.applyingChange)
            .removeDuplicates()
            .collect(3)
            .first())
        context.send(viewAction: .processToggleCalls)
        let states = try await deferred.fulfill()
        
        XCTAssertEqual(states, [false, true, false])
        XCTAssertNotNil(context.alertInfo)
    }
}
