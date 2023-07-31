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

import MatrixRustSDK
import XCTest

@testable import ElementX

@MainActor
class RoomNotificationSettingsScreenViewModelTests: XCTestCase {
    var viewModel: RoomNotificationSettingsScreenViewModel!
    var roomProxyMock: RoomProxyMock!
    var notificationSettingsProxyMock: NotificationSettingsProxyMock!
    var context: RoomNotificationSettingsScreenViewModelType.Context { viewModel.context }

    override func setUpWithError() throws {
        roomProxyMock = RoomProxyMock(with: .init(displayName: "Test", joinedMembersCount: 0))
        notificationSettingsProxyMock = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
        viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                            roomProxy: roomProxyMock)
    }

    func testInitialStateDefaultMode() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedActiveMembersCountReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: true))
        viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                            roomProxy: roomProxyMock)
        let deferred = deferFulfillment(context.$viewState.map(\.notificationSettingsState)
            .first(where: \.isLoaded))
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()

        XCTAssertFalse(context.allowCustomSetting)
    }
    
    func testInitialStateCustomMode() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedActiveMembersCountReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                            roomProxy: roomProxyMock)
        let deferred = deferFulfillment(context.$viewState.map(\.notificationSettingsState)
            .first(where: \.isLoaded))
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()

        XCTAssertTrue(context.allowCustomSetting)
    }
    
    func testInitialStateFailure() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedActiveMembersCountThrowableError = NotificationSettingsError.Generic(message: "error")
        viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                            roomProxy: roomProxyMock)
        let deferred = deferFulfillment(context.$viewState.map(\.notificationSettingsState)
            .first(where: \.isError))
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()

        let expectedAlertInfo = AlertInfo(id: RoomNotificationSettingsScreenErrorType.loadingSettingsFailed,
                                          title: L10n.commonError,
                                          message: L10n.screenRoomNotificationSettingsErrorLoadingSettings)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.id, expectedAlertInfo.id)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.title, expectedAlertInfo.title)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.message, expectedAlertInfo.message)
    }
    
    func testToggleAllCustomSettingOff() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedActiveMembersCountReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                            roomProxy: roomProxyMock)
        let deferred = deferFulfillment(context.$viewState.map(\.notificationSettingsState)
            .first(where: \.isLoaded))
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        let deferredIsRestoringDefaultSettings = deferFulfillment(context.$viewState.map(\.isRestoringDefautSetting)
            .removeDuplicates()
            .collect(3).first())
        viewModel.state.bindings.allowCustomSetting = false
        context.send(viewAction: .changedAllowCustomSettings)
        let states = try await deferredIsRestoringDefaultSettings.fulfill()
        XCTAssertEqual(states, [false, true, false])
        
        XCTAssertEqual(notificationSettingsProxyMock.restoreDefaultNotificationModeRoomIdReceivedRoomId, roomProxyMock.id)
        XCTAssertEqual(notificationSettingsProxyMock.restoreDefaultNotificationModeRoomIdCallsCount, 1)
    }
    
    func testToggleAllCustomSettingOffOn() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedActiveMembersCountReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: true))
        viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                            roomProxy: roomProxyMock)
        var deferred = deferFulfillment(context.$viewState.map(\.notificationSettingsState).first(where: \.isLoaded))
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.$viewState.map(\.notificationSettingsState).first(where: \.isLoaded))
        viewModel.state.bindings.allowCustomSetting = true
        context.send(viewAction: .changedAllowCustomSettings)
        try await deferred.fulfill()
        
        XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.0, roomProxyMock.id)
        XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.1, .mentionsAndKeywordsOnly)
        XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeCallsCount, 1)
    }
    
    func testSetCustomMode() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedActiveMembersCountReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                            roomProxy: roomProxyMock)
        let deferredState = deferFulfillment(context.$viewState.map(\.notificationSettingsState).first(where: \.isLoaded))
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferredState.fulfill()

        do {
            let deferredViewState = deferFulfillment(context.$viewState.collect(2).first())
            context.send(viewAction: .setCustomMode(.allMessages))
            try await deferredViewState.fulfill()
            
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.0, roomProxyMock.id)
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.1, .allMessages)
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeCallsCount, 1)
        }
        
        do {
            let deferredViewState = deferFulfillment(context.$viewState.collect(2).first())
            context.send(viewAction: .setCustomMode(.mute))
            try await deferredViewState.fulfill()
            
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.0, roomProxyMock.id)
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.1, .mute)
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeCallsCount, 2)
        }
        
        do {
            let deferredViewState = deferFulfillment(context.$viewState.collect(2).first())
            context.send(viewAction: .setCustomMode(.mentionsAndKeywordsOnly))
            try await deferredViewState.fulfill()
            
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.0, roomProxyMock.id)
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.1, .mentionsAndKeywordsOnly)
            XCTAssertEqual(notificationSettingsProxyMock.setNotificationModeRoomIdModeCallsCount, 3)
        }
    }
}
