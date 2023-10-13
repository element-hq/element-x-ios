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
class NotificationSettingsEditScreenViewModelTests: XCTestCase {
    private var viewModel: NotificationSettingsEditScreenViewModelProtocol!
    private var notificationSettingsProxy: NotificationSettingsProxyMock!
    private var userSession: UserSessionProtocol!
    
    private var context: NotificationSettingsEditScreenViewModelType.Context {
        viewModel.context
    }
    
    @MainActor override func setUpWithError() throws {
        let clientProxy = MockClientProxy(userID: "@a:b.com")
        userSession = MockUserSession(clientProxy: clientProxy,
                                      mediaProvider: MockMediaProvider(),
                                      voiceMessageMediaManager: VoiceMessageMediaManagerMock())
        notificationSettingsProxy = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .allMessages
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
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .groupChat,
                                                            userSession: userSession,
                                                            notificationSettingsProxy: notificationSettingsProxy)

        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.defaultMode != nil
        }
        
        viewModel.fetchInitialContent()
        
        try await deferred.fulfill()
        
        // `getDefaultRoomNotificationModeIsEncryptedIsOneToOne` must have been called twice (for encrypted and unencrypted group chats)
        let invocations = notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocations
        
        XCTAssertEqual(invocations.count, 2)
        // First call for encrypted group chats
        XCTAssertEqual(invocations[0].isEncrypted, true)
        XCTAssertEqual(invocations[0].isOneToOne, false)
        // Second call for unencrypted group chats
        XCTAssertEqual(invocations[1].isEncrypted, false)
        XCTAssertEqual(invocations[1].isOneToOne, false)
        
        XCTAssertEqual(context.viewState.defaultMode, .mentionsAndKeywordsOnly)
        XCTAssertNil(context.viewState.bindings.alertInfo)
    }
    
    func testSetModeAllMessages() async throws {
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .mentionsAndKeywordsOnly
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .groupChat,
                                                            userSession: userSession,
                                                            notificationSettingsProxy: notificationSettingsProxy)
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.defaultMode != nil
        }
        
        viewModel.fetchInitialContent()
        
        try await deferred.fulfill()
        
        var deferredViewState = deferFulfillment(viewModel.context.$viewState, keyPath: \.pendingMode, transitionValues: [nil, .allMessages, nil])

        context.send(viewAction: .setMode(.allMessages))
        
        try await deferredViewState.fulfill()
        
        // `setDefaultRoomNotificationModeIsEncryptedIsOneToOneMode` must have been called twice (for encrypted and unencrypted group chats)
        let invocations = notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations
        XCTAssertEqual(notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount, 2)
        // First call for encrypted group chats
        XCTAssertEqual(invocations[0].isEncrypted, true)
        XCTAssertEqual(invocations[0].isOneToOne, false)
        XCTAssertEqual(invocations[0].mode, .allMessages)
        // Second call for unencrypted group chats
        XCTAssertEqual(invocations[1].isEncrypted, false)
        XCTAssertEqual(invocations[1].isOneToOne, false)
        XCTAssertEqual(invocations[1].mode, .allMessages)
        
        deferredViewState = deferFulfillment(viewModel.context.$viewState,
                                             keyPath: \.defaultMode,
                                             transitionValues: [.allMessages])
        
        try await deferredViewState.fulfill()

        XCTAssertEqual(context.viewState.defaultMode, .allMessages)
        XCTAssertNil(context.viewState.bindings.alertInfo)
    }

    func testSetModeMentions() async throws {
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .groupChat,
                                                            userSession: userSession,
                                                            notificationSettingsProxy: notificationSettingsProxy)
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.defaultMode != nil
        }
        
        viewModel.fetchInitialContent()
        
        try await deferred.fulfill()
        
        var deferredViewState = deferFulfillment(viewModel.context.$viewState,
                                                 keyPath: \.pendingMode,
                                                 transitionValues: [nil, .mentionsAndKeywordsOnly, nil])
                
        context.send(viewAction: .setMode(.mentionsAndKeywordsOnly))
        
        try await deferredViewState.fulfill()
        
        // `setDefaultRoomNotificationModeIsEncryptedIsOneToOneMode` must have been called twice (for encrypted and unencrypted group chats)
        let invocations = notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations
        XCTAssertEqual(notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount, 2)
        // First call for encrypted group chats
        XCTAssertEqual(invocations[0].isEncrypted, true)
        XCTAssertEqual(invocations[0].isOneToOne, false)
        XCTAssertEqual(invocations[0].mode, .mentionsAndKeywordsOnly)
        // Second call for unencrypted group chats
        XCTAssertEqual(invocations[1].isEncrypted, false)
        XCTAssertEqual(invocations[1].isOneToOne, false)
        XCTAssertEqual(invocations[1].mode, .mentionsAndKeywordsOnly)
        
        deferredViewState = deferFulfillment(viewModel.context.$viewState,
                                             keyPath: \.defaultMode,
                                             transitionValues: [.mentionsAndKeywordsOnly])
        
        try await deferredViewState.fulfill()

        XCTAssertEqual(context.viewState.defaultMode, .mentionsAndKeywordsOnly)
        XCTAssertNil(context.viewState.bindings.alertInfo)
    }

    func testSetModeDirectChats() async throws {
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .mentionsAndKeywordsOnly
        // Initialize for direct chats
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .oneToOneChat,
                                                            userSession: userSession,
                                                            notificationSettingsProxy: notificationSettingsProxy)
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.defaultMode != nil
        }
        
        viewModel.fetchInitialContent()
        
        try await deferred.fulfill()
        
        let deferredViewState = deferFulfillment(viewModel.context.$viewState,
                                                 keyPath: \.pendingMode,
                                                 transitionValues: [nil, .allMessages, nil])
        
        context.send(viewAction: .setMode(.allMessages))
        
        try await deferredViewState.fulfill()

        // `setDefaultRoomNotificationModeIsEncryptedIsOneToOneMode` must have been called twice (for encrypted and unencrypted direct chats)
        let invocations = notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations
        XCTAssertEqual(notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount, 2)
        // First call for encrypted direct chats
        XCTAssertEqual(invocations[0].isEncrypted, true)
        XCTAssertEqual(invocations[0].isOneToOne, true)
        XCTAssertEqual(invocations[0].mode, .allMessages)
        // Second call for unencrypted direct chats
        XCTAssertEqual(invocations[1].isEncrypted, false)
        XCTAssertEqual(invocations[1].isOneToOne, true)
        XCTAssertEqual(invocations[1].mode, .allMessages)
    }

    func testSetModeFailure() async throws {
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .mentionsAndKeywordsOnly
        notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeThrowableError = NotificationSettingsError.Generic(msg: "error")
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .oneToOneChat,
                                                            userSession: userSession,
                                                            notificationSettingsProxy: notificationSettingsProxy)
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.defaultMode != nil
        }
        
        viewModel.fetchInitialContent()
        
        try await deferred.fulfill()
        
        let deferredViewState = deferFulfillment(viewModel.context.$viewState,
                                                 keyPath: \.pendingMode,
                                                 transitionValues: [nil, .allMessages, nil])

        context.send(viewAction: .setMode(.allMessages))
        
        try await deferredViewState.fulfill()
        
        XCTAssertNotNil(context.viewState.bindings.alertInfo)
    }

    func testSelectRoom() async throws {
        let roomID = "!roomidentifier:matrix.org"
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .oneToOneChat,
                                                            userSession: userSession,
                                                            notificationSettingsProxy: notificationSettingsProxy)
        
        let deferredActions = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .requestRoomNotificationSettingsPresentation:
                return true
            }
        }
        
        context.send(viewAction: .selectRoom(roomIdentifier: roomID))
        
        let sentAction = try await deferredActions.fulfill()
        
        let expectedAction = NotificationSettingsEditScreenViewModelAction.requestRoomNotificationSettingsPresentation(roomID: roomID)
        guard case let .requestRoomNotificationSettingsPresentation(roomID: receivedRoomID) = sentAction, receivedRoomID == roomID else {
            XCTFail("Expected action \(expectedAction), but was \(sentAction)")
            return
        }
    }
}
