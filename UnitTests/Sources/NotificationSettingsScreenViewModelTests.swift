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
    private var userSession: UserSessionProtocol!
    private var userNotificationCenter: UserNotificationCenterMock!
    private var notificationSettingsProxy: NotificationSettingsProxyMock!
    
    @MainActor override func setUpWithError() throws {
        AppSettings.reset()
        
        userNotificationCenter = UserNotificationCenterMock()
        userNotificationCenter.authorizationStatusReturnValue = .authorized
        appSettings = AppSettings()
        notificationSettingsProxy = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .allMessages
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = true
        notificationSettingsProxy.isCallEnabledReturnValue = true
        
        let clientProxy = MockClientProxy(userID: "@a:b.com")
        userSession = MockUserSession(clientProxy: clientProxy, mediaProvider: MockMediaProvider())
        
        viewModel = NotificationSettingsScreenViewModel(userSession: userSession,
                                                        appSettings: appSettings,
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
        let deferred = deferFulfillment(viewModel.context.$viewState.map(\.settings)
            .first(where: { $0 != nil }))
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        XCTAssertEqual(notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneCallsCount, 4)
        XCTAssert(notificationSettingsProxy.isRoomMentionEnabledCalled)
        XCTAssert(notificationSettingsProxy.isCallEnabledCalled)
        
        XCTAssertEqual(context.viewState.settings?.groupChatsMode, .mentionsAndKeywordsOnly)
        XCTAssertEqual(context.viewState.settings?.directChatsMode, .allMessages)
        XCTAssertEqual(context.viewState.settings?.inconsistentSettings, false)
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
                
        let deferred = deferFulfillment(viewModel.context.$viewState.map(\.settings)
            .first(where: { $0 != nil }))
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.settings?.groupChatsMode, .allMessages)
        XCTAssertEqual(context.viewState.settings?.inconsistentSettings, true)
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
                
        let deferred = deferFulfillment(viewModel.context.$viewState.map(\.settings)
            .first(where: { $0 != nil }))
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.settings?.directChatsMode, .allMessages)
        XCTAssertEqual(context.viewState.settings?.inconsistentSettings, true)
    }
    
    func testToggleRoomMentionOff() async throws {
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = true
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState.map(\.settings)
            .first(where: { $0 != nil }))
        notificationSettingsProxy.callbacks.send(.settingsDidChange)
        try await deferredInitialFetch.fulfill()
        
        context.roomMentionsEnabled = false
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks
            .first(where: { $0 == .settingsDidChange }))
        context.send(viewAction: .roomMentionChanged)
        try await deferred.fulfill()
        
        XCTAssert(notificationSettingsProxy.setRoomMentionEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setRoomMentionEnabledEnabledReceivedEnabled, false)
    }
    
    func testToggleRoomMentionOn() async throws {
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = false
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState.map(\.settings)
            .first(where: { $0 != nil }))
        viewModel.fetchInitialContent()
        try await deferredInitialFetch.fulfill()

        context.roomMentionsEnabled = true
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks
            .first(where: { $0 == .settingsDidChange }))
        context.send(viewAction: .roomMentionChanged)
        try await deferred.fulfill()
        
        XCTAssert(notificationSettingsProxy.setRoomMentionEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setRoomMentionEnabledEnabledReceivedEnabled, true)
    }
    
    func testToggleRoomMentionFailure() async throws {
        notificationSettingsProxy.setRoomMentionEnabledEnabledThrowableError = NotificationSettingsError.Generic(message: "error")
        notificationSettingsProxy.isRoomMentionEnabledReturnValue = false
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState.map(\.settings)
            .first(where: { $0 != nil }))
        viewModel.fetchInitialContent()
        try await deferredInitialFetch.fulfill()
                
        context.roomMentionsEnabled = true
        let deferred = deferFulfillment(context.$viewState.map(\.applyingChange)
            .removeDuplicates()
            .collect(3)
            .first())
        context.send(viewAction: .roomMentionChanged)
        let states = try await deferred.fulfill()
        
        XCTAssertEqual(states, [false, true, false])
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testToggleCallsOff() async throws {
        notificationSettingsProxy.isCallEnabledReturnValue = true
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState.map(\.settings)
            .first(where: { $0 != nil }))
        viewModel.fetchInitialContent()
        try await deferredInitialFetch.fulfill()
        
        context.callsEnabled = false
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks
            .first(where: { $0 == .settingsDidChange }))
        context.send(viewAction: .callsChanged)
        try await deferred.fulfill()
        
        XCTAssert(notificationSettingsProxy.setCallEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setCallEnabledEnabledReceivedEnabled, false)
    }
    
    func testToggleCallsOn() async throws {
        notificationSettingsProxy.isCallEnabledReturnValue = false
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState.map(\.settings)
            .first(where: { $0 != nil }))
        viewModel.fetchInitialContent()
        try await deferredInitialFetch.fulfill()

        context.callsEnabled = true
        let deferred = deferFulfillment(notificationSettingsProxy.callbacks
            .first(where: { $0 == .settingsDidChange }))
        context.send(viewAction: .callsChanged)
        try await deferred.fulfill()

        XCTAssert(notificationSettingsProxy.setCallEnabledEnabledCalled)
        XCTAssertEqual(notificationSettingsProxy.setCallEnabledEnabledReceivedEnabled, true)
    }
    
    func testToggleCallsFailure() async throws {
        notificationSettingsProxy.setCallEnabledEnabledThrowableError = NotificationSettingsError.Generic(message: "error")
        notificationSettingsProxy.isCallEnabledReturnValue = false
        let deferredInitialFetch = deferFulfillment(viewModel.context.$viewState.map(\.settings)
            .first(where: { $0 != nil }))
        viewModel.fetchInitialContent()
        try await deferredInitialFetch.fulfill()

        context.callsEnabled = true
        let deferred = deferFulfillment(context.$viewState.map(\.applyingChange)
            .removeDuplicates()
            .collect(3)
            .first())
        context.send(viewAction: .callsChanged)
        let states = try await deferred.fulfill()
        
        XCTAssertEqual(states, [false, true, false])
        XCTAssertNotNil(context.alertInfo)
    }
}
