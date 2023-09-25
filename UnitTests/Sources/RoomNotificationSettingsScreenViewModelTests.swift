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

import Combine
import MatrixRustSDK
import XCTest

@testable import ElementX

@MainActor
class RoomNotificationSettingsScreenViewModelTests: XCTestCase {
    var roomProxyMock: RoomProxyMock!
    var notificationSettingsProxyMock: NotificationSettingsProxyMock!
    var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        cancellables.removeAll()
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", joinedMembersCount: 0))
        notificationSettingsProxyMock = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
    }
    
    func testInitialStateDefaultMode() async throws {
        let roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", joinedMembersCount: 0))
        let notificationSettingsProxyMock = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
        
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: true))
        
        let viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                                roomProxy: roomProxyMock,
                                                                displayAsUserDefinedRoomSettings: false)

        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.notificationSettingsState.isLoaded
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()

        XCTAssertFalse(viewModel.context.allowCustomSetting)
    }
    
    func testInitialStateCustomMode() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        let viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                                roomProxy: roomProxyMock,
                                                                displayAsUserDefinedRoomSettings: false)
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.notificationSettingsState.isLoaded
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()

        XCTAssertTrue(viewModel.context.allowCustomSetting)
    }
    
    func testInitialStateFailure() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneThrowableError = NotificationSettingsError.Generic(message: "error")
        let viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                                roomProxy: roomProxyMock,
                                                                displayAsUserDefinedRoomSettings: false)
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.notificationSettingsState.isError
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()

        let expectedAlertInfo = AlertInfo(id: RoomNotificationSettingsScreenErrorType.loadingSettingsFailed,
                                          title: L10n.commonError,
                                          message: L10n.screenRoomNotificationSettingsErrorLoadingSettings)
        XCTAssertEqual(viewModel.context.viewState.bindings.alertInfo?.id, expectedAlertInfo.id)
        XCTAssertEqual(viewModel.context.viewState.bindings.alertInfo?.title, expectedAlertInfo.title)
        XCTAssertEqual(viewModel.context.viewState.bindings.alertInfo?.message, expectedAlertInfo.message)
    }
    
    func testToggleAllCustomSettingOff() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        let viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                                roomProxy: roomProxyMock,
                                                                displayAsUserDefinedRoomSettings: false)
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.notificationSettingsState.isLoaded
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        viewModel.state.bindings.allowCustomSetting = false
        viewModel.context.send(viewAction: .changedAllowCustomSettings)
        
        let deferredIsRestoringDefaultSettings = deferFulfillment(viewModel.context.$viewState) { state in
            state.isRestoringDefaultSetting == false
        }
        
        try await deferredIsRestoringDefaultSettings.fulfill()
        
        XCTAssertEqual(notificationSettingsProxyMock.restoreDefaultNotificationModeRoomIdReceivedRoomId, roomProxyMock.id)
        XCTAssertEqual(notificationSettingsProxyMock.restoreDefaultNotificationModeRoomIdCallsCount, 1)
    }
    
    func testToggleAllCustomSettingOffOn() async throws {
        let notificationSettingsProxyMock = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: true))
        let viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                                roomProxy: roomProxyMock,
                                                                displayAsUserDefinedRoomSettings: false)
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.notificationSettingsState.isLoaded
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        
        try await deferred.fulfill()
        
        deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.notificationSettingsState.isLoaded
        }
        
        viewModel.state.bindings.allowCustomSetting = true
        viewModel.context.send(viewAction: .changedAllowCustomSettings)
        
        try await deferred.fulfill()
        
        XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.0, roomProxyMock.id)
        XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.1, .mentionsAndKeywordsOnly)
        XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeCallsCount, 1)
    }
    
    func testSetCustomMode() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        let viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                                roomProxy: roomProxyMock,
                                                                displayAsUserDefinedRoomSettings: false)
        
        let deferredState = deferFulfillment(viewModel.context.$viewState) { state in
            state.notificationSettingsState.isLoaded
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferredState.fulfill()

        do {
            viewModel.context.send(viewAction: .setCustomMode(.allMessages))
            
            let deferredState = deferFulfillment(viewModel.context.$viewState) { state in
                state.pendingCustomMode == nil
            }
            
            try await deferredState.fulfill()
            
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.0, roomProxyMock.id)
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.1, .allMessages)
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeCallsCount, 1)
        }
        
        do {
            viewModel.context.send(viewAction: .setCustomMode(.mute))
            
            let deferredState = deferFulfillment(viewModel.context.$viewState) { state in
                state.pendingCustomMode == nil
            }
            
            try await deferredState.fulfill()
            
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.0, roomProxyMock.id)
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.1, .mute)
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeCallsCount, 2)
        }
        
        do {
            viewModel.context.send(viewAction: .setCustomMode(.mentionsAndKeywordsOnly))
            
            let deferredState = deferFulfillment(viewModel.context.$viewState) { state in
                state.pendingCustomMode == nil
            }
            
            try await deferredState.fulfill()
            
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.0, roomProxyMock.id)
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.1, .mentionsAndKeywordsOnly)
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeCallsCount, 3)
        }
    }
    
    func testDeleteCustomSettingTapped() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        let viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                                roomProxy: roomProxyMock,
                                                                displayAsUserDefinedRoomSettings: true)
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.notificationSettingsState.isLoaded
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        var actionSent: RoomNotificationSettingsScreenViewModelAction?
        viewModel.actions
            .sink { action in
                actionSent = action
            }
            .store(in: &cancellables)
        
        viewModel.context.send(viewAction: .deleteCustomSettingTapped)
        
        let deferredViewState = deferFulfillment(viewModel.context.$viewState) { state in
            state.deletingCustomSetting == false
        }
        
        try await deferredViewState.fulfill()
        
        // the `dismiss` action must have been sent
        XCTAssertEqual(actionSent, .dismiss)
        // `restoreDefaultNotificationMode` should have been called
        XCTAssert(notificationSettingsProxyMock.restoreDefaultNotificationModeRoomIdCalled)
        XCTAssertEqual(notificationSettingsProxyMock.restoreDefaultNotificationModeRoomIdReceivedInvocations, [roomProxyMock.id])
        // and no alert is expected
        XCTAssertNil(viewModel.context.alertInfo)
    }
    
    func testDeleteCustomSettingTappedFailure() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        notificationSettingsProxyMock.restoreDefaultNotificationModeRoomIdThrowableError = NotificationSettingsError.Generic(message: "error")
        let viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                                roomProxy: roomProxyMock,
                                                                displayAsUserDefinedRoomSettings: true)
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.notificationSettingsState.isLoaded
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        var actionSent: RoomNotificationSettingsScreenViewModelAction?
        viewModel.actions
            .sink { action in
                actionSent = action
            }
            .store(in: &cancellables)
        
        viewModel.context.send(viewAction: .deleteCustomSettingTapped)
        
        let deferredViewState = deferFulfillment(viewModel.context.$viewState) { state in
            state.deletingCustomSetting == false
        }
        
        try await deferredViewState.fulfill()
        
        // an alert is expected
        XCTAssertEqual(viewModel.context.alertInfo?.id, .restoreDefaultFailed)
        // the `dismiss` action must not have been sent
        XCTAssertNil(actionSent)
    }
}
