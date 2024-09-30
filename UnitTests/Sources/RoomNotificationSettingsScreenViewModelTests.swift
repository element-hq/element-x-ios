//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import MatrixRustSDK
import XCTest

@testable import ElementX

@MainActor
class RoomNotificationSettingsScreenViewModelTests: XCTestCase {
    var roomProxyMock: JoinedRoomProxyMock!
    var notificationSettingsProxyMock: NotificationSettingsProxyMock!
    var cancellables = Set<AnyCancellable>()

    override func setUpWithError() throws {
        cancellables.removeAll()
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test"))
        notificationSettingsProxyMock = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
    }
    
    func testInitialStateDefaultModeEncryptedRoom() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isEncrypted: true))
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
        XCTAssertTrue(viewModel.context.viewState.shouldDisplayMentionsOnlyDisclaimer)
        XCTAssertNotNil(viewModel.context.viewState.description(mode: .mentionsAndKeywordsOnly))
    }
    
    func testInitialStateDefaultModeEncryptedRoomWithCanPushEncrypted() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isEncrypted: true))
        let notificationSettingsProxyMock = NotificationSettingsProxyMock(with: .init(canPushEncryptedEvents: true))
        
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
        XCTAssertFalse(viewModel.context.viewState.shouldDisplayMentionsOnlyDisclaimer)
        XCTAssertNil(viewModel.context.viewState.description(mode: .mentionsAndKeywordsOnly))
    }
    
    func testInitialStateDefaultModeUnencryptedRoom() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isEncrypted: false))
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
        XCTAssertFalse(viewModel.context.viewState.shouldDisplayMentionsOnlyDisclaimer)
        XCTAssertNil(viewModel.context.viewState.description(mode: .mentionsAndKeywordsOnly))
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
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneThrowableError = NotificationSettingsError.Generic(msg: "error")
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
                
        let deferredIsRestoringDefaultSettings = deferFulfillment(viewModel.context.$viewState,
                                                                  keyPath: \.isRestoringDefaultSetting,
                                                                  transitionValues: [false, true, false])
        
        viewModel.state.bindings.allowCustomSetting = false
        viewModel.context.send(viewAction: .changedAllowCustomSettings)
        
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
        
        let deferredViewState = deferFulfillment(viewModel.context.$viewState,
                                                 keyPath: \.deletingCustomSetting,
                                                 transitionValues: [false, true, false])
        
        viewModel.context.send(viewAction: .deleteCustomSettingTapped)
        
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
        notificationSettingsProxyMock.restoreDefaultNotificationModeRoomIdThrowableError = NotificationSettingsError.Generic(msg: "error")
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
        
        let deferredViewState = deferFulfillment(viewModel.context.$viewState,
                                                 keyPath: \.deletingCustomSetting,
                                                 transitionValues: [false, true, false])
        
        viewModel.context.send(viewAction: .deleteCustomSettingTapped)
        
        try await deferredViewState.fulfill()
                
        // an alert is expected
        XCTAssertEqual(viewModel.context.alertInfo?.id, .restoreDefaultFailed)
        // the `dismiss` action must not have been sent
        XCTAssertNil(actionSent)
    }
}
