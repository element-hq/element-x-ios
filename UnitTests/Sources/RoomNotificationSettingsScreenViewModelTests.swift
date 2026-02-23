//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import MatrixRustSDK
import Testing

@Suite
@MainActor
struct RoomNotificationSettingsScreenViewModelTests {
    var roomProxyMock: JoinedRoomProxyMock!
    var notificationSettingsProxyMock: NotificationSettingsProxyMock!
    var cancellables = Set<AnyCancellable>()

    init() throws {
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test"))
        notificationSettingsProxyMock = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
    }
    
    @Test
    func initialStateDefaultModeEncryptedRoom() async throws {
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

        #expect(!viewModel.context.allowCustomSetting)
        #expect(viewModel.context.viewState.shouldDisplayMentionsOnlyDisclaimer)
        #expect(viewModel.context.viewState.description(mode: .mentionsAndKeywordsOnly) != nil)
    }
    
    @Test
    func initialStateDefaultModeEncryptedRoomWithCanPushEncrypted() async throws {
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

        #expect(!viewModel.context.allowCustomSetting)
        #expect(!viewModel.context.viewState.shouldDisplayMentionsOnlyDisclaimer)
        #expect(viewModel.context.viewState.description(mode: .mentionsAndKeywordsOnly) == nil)
    }
    
    @Test
    func initialStateDefaultModeUnencryptedRoom() async throws {
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

        #expect(!viewModel.context.allowCustomSetting)
        #expect(!viewModel.context.viewState.shouldDisplayMentionsOnlyDisclaimer)
        #expect(viewModel.context.viewState.description(mode: .mentionsAndKeywordsOnly) == nil)
    }
    
    @Test
    func initialStateCustomMode() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        let viewModel = RoomNotificationSettingsScreenViewModel(notificationSettingsProxy: notificationSettingsProxyMock,
                                                                roomProxy: roomProxyMock,
                                                                displayAsUserDefinedRoomSettings: false)
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.notificationSettingsState.isLoaded
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()

        #expect(viewModel.context.allowCustomSetting)
    }
    
    @Test
    func initialStateFailure() async throws {
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
        #expect(viewModel.context.viewState.bindings.alertInfo?.id == expectedAlertInfo.id)
        #expect(viewModel.context.viewState.bindings.alertInfo?.title == expectedAlertInfo.title)
        #expect(viewModel.context.viewState.bindings.alertInfo?.message == expectedAlertInfo.message)
    }
    
    @Test
    func toggleAllCustomSettingOff() async throws {
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
        
        #expect(notificationSettingsProxyMock.restoreDefaultNotificationModeRoomIdReceivedRoomId == roomProxyMock.id)
        #expect(notificationSettingsProxyMock.restoreDefaultNotificationModeRoomIdCallsCount == 1)
    }
    
    @Test
    func toggleAllCustomSettingOffOn() async throws {
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
        
        #expect(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.0 == roomProxyMock.id)
        #expect(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.1 == .mentionsAndKeywordsOnly)
        #expect(notificationSettingsProxyMock.setNotificationModeRoomIdModeCallsCount == 1)
    }
    
    @Test
    func setCustomMode() async throws {
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
            
            #expect(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.0 == roomProxyMock.id)
            #expect(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.1 == .allMessages)
            #expect(notificationSettingsProxyMock.setNotificationModeRoomIdModeCallsCount == 1)
        }
        
        do {
            viewModel.context.send(viewAction: .setCustomMode(.mute))
            
            let deferredState = deferFulfillment(viewModel.context.$viewState) { state in
                state.pendingCustomMode == nil
            }
            
            try await deferredState.fulfill()
            
            #expect(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.0 == roomProxyMock.id)
            #expect(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.1 == .mute)
            #expect(notificationSettingsProxyMock.setNotificationModeRoomIdModeCallsCount == 2)
        }
        
        do {
            viewModel.context.send(viewAction: .setCustomMode(.mentionsAndKeywordsOnly))
            
            let deferredState = deferFulfillment(viewModel.context.$viewState) { state in
                state.pendingCustomMode == nil
            }
            
            try await deferredState.fulfill()
            
            #expect(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.0 == roomProxyMock.id)
            #expect(notificationSettingsProxyMock.setNotificationModeRoomIdModeReceivedArguments?.1 == .mentionsAndKeywordsOnly)
            #expect(notificationSettingsProxyMock.setNotificationModeRoomIdModeCallsCount == 3)
        }
    }
    
    @Test
    mutating func deleteCustomSettingTapped() async throws {
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
        #expect(actionSent == .dismiss)
        // `restoreDefaultNotificationMode` should have been called
        #expect(notificationSettingsProxyMock.restoreDefaultNotificationModeRoomIdCalled)
        #expect(notificationSettingsProxyMock.restoreDefaultNotificationModeRoomIdReceivedInvocations == [roomProxyMock.id])
        // and no alert is expected
        #expect(viewModel.context.alertInfo == nil)
    }
    
    @Test
    mutating func deleteCustomSettingTappedFailure() async throws {
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
        #expect(viewModel.context.alertInfo?.id == .restoreDefaultFailed)
        // the `dismiss` action must not have been sent
        #expect(actionSent == nil)
    }
}
