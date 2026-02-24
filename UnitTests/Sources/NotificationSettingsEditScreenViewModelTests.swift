//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import MatrixRustSDK
import Testing

@Suite
@MainActor
struct NotificationSettingsEditScreenViewModelTests {
    private var viewModel: NotificationSettingsEditScreenViewModelProtocol!
    private var notificationSettingsProxy: NotificationSettingsProxyMock!
    private var userSession: UserSessionMock!
    private var clientProxy: ClientProxyMock!
    
    private var context: NotificationSettingsEditScreenViewModelType.Context {
        viewModel.context
    }
    
    init() throws {
        notificationSettingsProxy = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .allMessages
        
        clientProxy = ClientProxyMock(.init(userID: "@a:b.com", notificationSettings: notificationSettingsProxy))
        userSession = UserSessionMock(.init(clientProxy: clientProxy))
    }
    
    @Test
    mutating func fetchSettings() async throws {
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = { isEncrypted, isOneToOne in
            switch (isEncrypted, isOneToOne) {
            case (_, true):
                return .allMessages
            case (_, _):
                return .mentionsAndKeywordsOnly
            }
        }
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .groupChat, userSession: userSession)

        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.defaultMode)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferred.fulfill()
        
        // `getDefaultRoomNotificationModeIsEncryptedIsOneToOne` must have been called twice (for encrypted and unencrypted group chats)
        let invocations = notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocations
        
        #expect(invocations.count == 2)
        // First call for encrypted group chats
        #expect(invocations[0].isEncrypted == true)
        #expect(invocations[0].isOneToOne == false)
        // Second call for unencrypted group chats
        #expect(invocations[1].isEncrypted == false)
        #expect(invocations[1].isOneToOne == false)
        
        #expect(context.viewState.defaultMode == .mentionsAndKeywordsOnly)
        #expect(context.viewState.bindings.alertInfo == nil)
        #expect(!context.viewState.canPushEncryptedEvents)
        #expect(context.viewState.description(for: .mentionsAndKeywordsOnly) != nil)
    }
    
    @Test
    mutating func fetchSettingsWithCanPushEncryptedEvents() async throws {
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneClosure = { isEncrypted, isOneToOne in
            switch (isEncrypted, isOneToOne) {
            case (_, true):
                return .allMessages
            case (_, _):
                return .mentionsAndKeywordsOnly
            }
        }
        notificationSettingsProxy.canPushEncryptedEventsToDeviceClosure = {
            true
        }
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .groupChat, userSession: userSession)

        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.defaultMode)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferred.fulfill()
        
        // `getDefaultRoomNotificationModeIsEncryptedIsOneToOne` must have been called twice (for encrypted and unencrypted group chats)
        let invocations = notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReceivedInvocations
        
        #expect(invocations.count == 2)
        // First call for encrypted group chats
        #expect(invocations[0].isEncrypted == true)
        #expect(invocations[0].isOneToOne == false)
        // Second call for unencrypted group chats
        #expect(invocations[1].isEncrypted == false)
        #expect(invocations[1].isOneToOne == false)
        
        #expect(context.viewState.defaultMode == .mentionsAndKeywordsOnly)
        #expect(context.viewState.bindings.alertInfo == nil)
        #expect(context.viewState.canPushEncryptedEvents)
        #expect(context.viewState.description(for: .mentionsAndKeywordsOnly) == nil)
    }
    
    @Test
    mutating func setModeAllMessages() async throws {
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .mentionsAndKeywordsOnly
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .groupChat, userSession: userSession)
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.defaultMode)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferred.fulfill()
        
        var deferredViewState = deferFulfillment(viewModel.context.observe(\.viewState.pendingMode),
                                                 transitionValues: [nil, .allMessages, nil])

        context.send(viewAction: .setMode(.allMessages))
        
        try await deferredViewState.fulfill()
        
        // `setDefaultRoomNotificationModeIsEncryptedIsOneToOneMode` must have been called twice (for encrypted and unencrypted group chats)
        let invocations = notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations
        #expect(notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount == 2)
        // First call for encrypted group chats
        #expect(invocations[0].isEncrypted == true)
        #expect(invocations[0].isOneToOne == false)
        #expect(invocations[0].mode == .allMessages)
        // Second call for unencrypted group chats
        #expect(invocations[1].isEncrypted == false)
        #expect(invocations[1].isOneToOne == false)
        #expect(invocations[1].mode == .allMessages)
        
        deferredViewState = deferFulfillment(viewModel.context.observe(\.viewState.defaultMode),
                                             transitionValues: [.allMessages])
        
        try await deferredViewState.fulfill()

        #expect(context.viewState.defaultMode == .allMessages)
        #expect(context.viewState.bindings.alertInfo == nil)
    }

    @Test
    mutating func setModeMentions() async throws {
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .groupChat, userSession: userSession)
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.defaultMode)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferred.fulfill()
        
        var deferredViewState = deferFulfillment(viewModel.context.observe(\.viewState.pendingMode),
                                                 transitionValues: [nil, .mentionsAndKeywordsOnly, nil])
                
        context.send(viewAction: .setMode(.mentionsAndKeywordsOnly))
        
        try await deferredViewState.fulfill()
        
        // `setDefaultRoomNotificationModeIsEncryptedIsOneToOneMode` must have been called twice (for encrypted and unencrypted group chats)
        let invocations = notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations
        #expect(notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount == 2)
        // First call for encrypted group chats
        #expect(invocations[0].isEncrypted == true)
        #expect(invocations[0].isOneToOne == false)
        #expect(invocations[0].mode == .mentionsAndKeywordsOnly)
        // Second call for unencrypted group chats
        #expect(invocations[1].isEncrypted == false)
        #expect(invocations[1].isOneToOne == false)
        #expect(invocations[1].mode == .mentionsAndKeywordsOnly)
        
        deferredViewState = deferFulfillment(viewModel.context.observe(\.viewState.defaultMode),
                                             transitionValues: [.mentionsAndKeywordsOnly])
        
        try await deferredViewState.fulfill()

        #expect(context.viewState.defaultMode == .mentionsAndKeywordsOnly)
        #expect(context.viewState.bindings.alertInfo == nil)
    }

    @Test
    mutating func setModeDirectChats() async throws {
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .mentionsAndKeywordsOnly
        // Initialize for direct chats
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .oneToOneChat, userSession: userSession)
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.defaultMode)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferred.fulfill()
        
        let deferredViewState = deferFulfillment(viewModel.context.observe(\.viewState.pendingMode),
                                                 transitionValues: [nil, .allMessages, nil])
        
        context.send(viewAction: .setMode(.allMessages))
        
        try await deferredViewState.fulfill()

        // `setDefaultRoomNotificationModeIsEncryptedIsOneToOneMode` must have been called twice (for encrypted and unencrypted direct chats)
        let invocations = notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeReceivedInvocations
        #expect(notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeCallsCount == 2)
        // First call for encrypted direct chats
        #expect(invocations[0].isEncrypted == true)
        #expect(invocations[0].isOneToOne == true)
        #expect(invocations[0].mode == .allMessages)
        // Second call for unencrypted direct chats
        #expect(invocations[1].isEncrypted == false)
        #expect(invocations[1].isOneToOne == true)
        #expect(invocations[1].mode == .allMessages)
    }

    @Test
    mutating func setModeFailure() async throws {
        notificationSettingsProxy.getDefaultRoomNotificationModeIsEncryptedIsOneToOneReturnValue = .mentionsAndKeywordsOnly
        notificationSettingsProxy.setDefaultRoomNotificationModeIsEncryptedIsOneToOneModeThrowableError = NotificationSettingsError.Generic(msg: "error")
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .oneToOneChat, userSession: userSession)
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.defaultMode)) { $0 != nil }
        
        viewModel.fetchInitialContent()
        
        try await deferred.fulfill()
        
        let deferredViewState = deferFulfillment(viewModel.context.observe(\.viewState.pendingMode),
                                                 transitionValues: [nil, .allMessages, nil])

        context.send(viewAction: .setMode(.allMessages))
        
        try await deferredViewState.fulfill()
        
        #expect(context.viewState.bindings.alertInfo != nil)
    }

    @Test
    mutating func selectRoom() async throws {
        let roomID = "!roomidentifier:matrix.org"
        viewModel = NotificationSettingsEditScreenViewModel(chatType: .oneToOneChat, userSession: userSession)
        
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
            Issue.record("Expected action \(expectedAction), but was \(sentAction)")
            return
        }
    }
}
