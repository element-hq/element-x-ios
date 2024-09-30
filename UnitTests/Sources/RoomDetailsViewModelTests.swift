//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import MatrixRustSDK
import SwiftUI
import XCTest

@testable import ElementX

@MainActor
class RoomDetailsScreenViewModelTests: XCTestCase {
    var viewModel: RoomDetailsScreenViewModel!
    var roomProxyMock: JoinedRoomProxyMock!
    var notificationSettingsProxyMock: NotificationSettingsProxyMock!
    var context: RoomDetailsScreenViewModelType.Context { viewModel.context }
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        cancellables.removeAll()
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test"))
        notificationSettingsProxyMock = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: notificationSettingsProxyMock,
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        AppSettings.resetAllSettings()
    }
    
    func testLeaveRoomTappedWhenPublic() async throws {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isPublic: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        let deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.leaveRoomAlertItem != nil
        }
        
        context.send(viewAction: .processTapLeave)
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.bindings.leaveRoomAlertItem?.state, .public)
        XCTAssertEqual(context.viewState.bindings.leaveRoomAlertItem?.subtitle, L10n.leaveRoomAlertSubtitle)
    }
    
    func testLeaveRoomTappedWhenRoomNotPublic() async throws {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        let deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.leaveRoomAlertItem != nil
        }
        
        context.send(viewAction: .processTapLeave)
        
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.bindings.leaveRoomAlertItem?.state, .private)
        XCTAssertEqual(context.viewState.bindings.leaveRoomAlertItem?.subtitle, L10n.leaveRoomAlertPrivateSubtitle)
    }
    
    func testLeaveRoomTappedWithLessThanTwoMembers() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        context.send(viewAction: .processTapLeave)
        XCTAssertEqual(context.leaveRoomAlertItem?.state, .empty)
        XCTAssertEqual(context.leaveRoomAlertItem?.subtitle, L10n.leaveRoomAlertEmptySubtitle)
    }
    
    func testLeaveRoomSuccess() async throws {
        roomProxyMock.leaveRoomClosure = {
            .success(())
        }
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .leftRoom:
                return true
            default:
                return false
            }
        }
        
        context.send(viewAction: .confirmLeave)
        
        try await deferred.fulfill()
        
        XCTAssertEqual(roomProxyMock.leaveRoomCallsCount, 1)
    }
    
    func testLeaveRoomError() async {
        let expectation = expectation(description: #function)
        roomProxyMock.leaveRoomClosure = {
            defer {
                expectation.fulfill()
            }
            return .failure(.sdkError(ClientProxyMockError.generic))
        }
        context.send(viewAction: .confirmLeave)
        await fulfillment(of: [expectation])
        XCTAssertEqual(roomProxyMock.leaveRoomCallsCount, 1)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testInitialDMDetailsState() async throws {
        let recipient = RoomMemberProxyMock.mockDan
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        let deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.dmRecipient != nil
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))
    }
    
    func testIgnoreSuccess() async throws {
        let recipient = RoomMemberProxyMock.mockDan
        
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.dmRecipient != nil
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))
        
        deferred = deferFulfillment(viewModel.context.$viewState,
                                    keyPath: \.isProcessingIgnoreRequest,
                                    transitionValues: [false, true, false])
        
        context.send(viewAction: .ignoreConfirmed)
        
        try await deferred.fulfill()
        
        XCTAssert(context.viewState.dmRecipient?.isIgnored == true)
    }
    
    func testIgnoreFailure() async throws {
        let recipient = RoomMemberProxyMock.mockDan
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        let clientProxy = ClientProxyMock(.init())
        clientProxy.ignoreUserReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: clientProxy,
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.dmRecipient != nil
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))
        
        deferred = deferFulfillment(viewModel.context.$viewState,
                                    keyPath: \.isProcessingIgnoreRequest,
                                    transitionValues: [false, true, false])
        
        context.send(viewAction: .ignoreConfirmed)
        
        try await deferred.fulfill()
        
        XCTAssert(context.viewState.dmRecipient?.isIgnored == false)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testUnignoreSuccess() async throws {
        let recipient = RoomMemberProxyMock.mockIgnored
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.dmRecipient != nil
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))
        
        deferred = deferFulfillment(viewModel.context.$viewState,
                                    keyPath: \.isProcessingIgnoreRequest,
                                    transitionValues: [false, true, false])
        
        context.send(viewAction: .unignoreConfirmed)
                
        try await deferred.fulfill()
        
        XCTAssert(context.viewState.dmRecipient?.isIgnored == false)
    }
    
    func testUnignoreFailure() async throws {
        let recipient = RoomMemberProxyMock.mockIgnored
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        let clientProxy = ClientProxyMock(.init())
        clientProxy.unignoreUserReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: clientProxy,
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        var deferred = deferFulfillment(viewModel.context.$viewState) { state in
            state.dmRecipient != nil
        }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.dmRecipient, RoomMemberDetails(withProxy: recipient))
        
        deferred = deferFulfillment(viewModel.context.$viewState,
                                    keyPath: \.isProcessingIgnoreRequest,
                                    transitionValues: [false, true, false])
        
        context.send(viewAction: .unignoreConfirmed)
                
        try await deferred.fulfill()
        
        XCTAssert(context.viewState.dmRecipient?.isIgnored == true)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testCannotInvitePeople() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test",
                                                  isPublic: true,
                                                  members: mockedMembers,
                                                  canUserInvite: false))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertFalse(context.viewState.canInviteUsers)
    }
    
    func testInvitePeople() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isPublic: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertTrue(context.viewState.canInviteUsers)
        
        var callbackCorrectlyCalled = false
        viewModel.actions
            .sink { action in
                switch action {
                case .requestInvitePeoplePresentation:
                    callbackCorrectlyCalled = true
                default:
                    callbackCorrectlyCalled = false
                }
            }
            .store(in: &cancellables)
        
        context.send(viewAction: .processTapInvite)
        await Task.yield()
        XCTAssertTrue(callbackCorrectlyCalled)
    }
    
    func testCanEditAvatar() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: false, isPublic: false, members: mockedMembers))
        roomProxyMock.canUserUserIDSendStateEventClosure = { _, event in
            .success(event == .roomAvatar)
        }
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertTrue(context.viewState.canEditRoomAvatar)
        XCTAssertFalse(context.viewState.canEditRoomName)
        XCTAssertFalse(context.viewState.canEditRoomTopic)
        XCTAssertTrue(context.viewState.canEdit)
    }
    
    func testCanEditName() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: false, isPublic: false, members: mockedMembers))
        roomProxyMock.canUserUserIDSendStateEventClosure = { _, event in
            .success(event == .roomName)
        }
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertFalse(context.viewState.canEditRoomAvatar)
        XCTAssertTrue(context.viewState.canEditRoomName)
        XCTAssertFalse(context.viewState.canEditRoomTopic)
        XCTAssertTrue(context.viewState.canEdit)
    }
    
    func testCanEditTopic() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: false, isPublic: false, members: mockedMembers))
        roomProxyMock.canUserUserIDSendStateEventClosure = { _, event in
            .success(event == .roomTopic)
        }
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertFalse(context.viewState.canEditRoomAvatar)
        XCTAssertFalse(context.viewState.canEditRoomName)
        XCTAssertTrue(context.viewState.canEditRoomTopic)
        XCTAssertTrue(context.viewState.canEdit)
    }
    
    func testCannotEditRoom() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: false, isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertFalse(context.viewState.canEditRoomAvatar)
        XCTAssertFalse(context.viewState.canEditRoomName)
        XCTAssertFalse(context.viewState.canEditRoomTopic)
        XCTAssertFalse(context.viewState.canEdit)
    }
    
    func testCannotEditDirectRoom() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMeAdmin, .mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: true, isPublic: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertFalse(context.viewState.canEdit)
    }
    
    // MARK: - Notifications
    
    func testNotificationLoadingSettingsFailure() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneThrowableError = NotificationSettingsError.Generic(msg: "error")
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               clientProxy: ClientProxyMock(.init()),
                                               mediaProvider: MockMediaProvider(),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: notificationSettingsProxyMock,
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appMediator: AppMediatorMock.default,
                                               appSettings: ServiceLocator.shared.settings)
        
        var deferred = deferFulfillment(context.$viewState) { state in
            state.notificationSettingsState.isError
        }
        
        try await deferred.fulfill()
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        
        deferred = deferFulfillment(context.$viewState) { state in
            state.notificationSettingsState.isError
        }
        
        try await deferred.fulfill()
        
        let expectedAlertInfo = AlertInfo(id: RoomDetailsScreenErrorType.alert,
                                          title: L10n.commonError,
                                          message: L10n.screenRoomDetailsErrorLoadingNotificationSettings)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.id, expectedAlertInfo.id)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.title, expectedAlertInfo.title)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.message, expectedAlertInfo.message)
    }
    
    func testNotificationDefaultMode() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .allMessages, isDefault: true))
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.notificationSettingsState.isLoaded
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.notificationSettingsState.label, "Default")
    }
    
    func testNotificationCustomMode() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .allMessages, isDefault: false))
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.notificationSettingsState.isCustom
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.notificationSettingsState.label, "Custom")
    }
    
    func testNotificationRoomMuted() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mute, isDefault: false))
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.notificationSettingsState.isLoaded
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        _ = await context.$viewState.debounce(for: .milliseconds(100), scheduler: DispatchQueue.main).values.first()
        
        XCTAssertEqual(context.viewState.notificationShortcutButtonTitle, L10n.commonUnmute)
        XCTAssertEqual(context.viewState.notificationShortcutButtonIcon, \.notificationsOff)
    }
    
    func testNotificationRoomNotMuted() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.notificationSettingsState.isLoaded
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.notificationShortcutButtonTitle, L10n.commonMute)
        XCTAssertEqual(context.viewState.notificationShortcutButtonIcon, \.notifications)
    }
    
    func testUnmuteTappedFailure() async throws {
        try await testNotificationRoomMuted()
        
        let expectation = expectation(description: #function)
        notificationSettingsProxyMock.unmuteRoomRoomIdIsEncryptedIsOneToOneClosure = { _, _, _ in
            defer {
                expectation.fulfill()
            }
            throw NotificationSettingsError.Generic(msg: "unmute error")
        }
        context.send(viewAction: .processToggleMuteNotifications)
        await fulfillment(of: [expectation])
        
        XCTAssertFalse(context.viewState.isProcessingMuteToggleAction)
        XCTAssertEqual(context.viewState.notificationShortcutButtonTitle, L10n.commonUnmute)
        
        let expectedAlertInfo = AlertInfo(id: RoomDetailsScreenErrorType.alert,
                                          title: L10n.commonError,
                                          message: L10n.screenRoomDetailsErrorUnmuting)
        
        XCTAssertEqual(context.viewState.bindings.alertInfo?.id, expectedAlertInfo.id)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.title, expectedAlertInfo.title)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.message, expectedAlertInfo.message)
    }
    
    func testMuteTappedFailure() async throws {
        try await testNotificationRoomNotMuted()
        
        let expectation = expectation(description: #function)
        notificationSettingsProxyMock.setNotificationModeRoomIdModeClosure = { _, _ in
            defer {
                expectation.fulfill()
            }
            throw NotificationSettingsError.Generic(msg: "mute error")
        }
        context.send(viewAction: .processToggleMuteNotifications)
        await fulfillment(of: [expectation])
        
        XCTAssertFalse(context.viewState.isProcessingMuteToggleAction)
        XCTAssertEqual(context.viewState.notificationShortcutButtonTitle, L10n.commonMute)
        
        let expectedAlertInfo = AlertInfo(id: RoomDetailsScreenErrorType.alert,
                                          title: L10n.commonError,
                                          message: L10n.screenRoomDetailsErrorMuting)
        
        XCTAssertEqual(context.viewState.bindings.alertInfo?.id, expectedAlertInfo.id)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.title, expectedAlertInfo.title)
        XCTAssertEqual(context.viewState.bindings.alertInfo?.message, expectedAlertInfo.message)
    }
    
    func testMuteTapped() async throws {
        try await testNotificationRoomNotMuted()
        
        let expectation = expectation(description: #function)
        notificationSettingsProxyMock.setNotificationModeRoomIdModeClosure = { [weak notificationSettingsProxyMock] _, mode in
            notificationSettingsProxyMock?.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: mode, isDefault: false))
            expectation.fulfill()
        }
        context.send(viewAction: .processToggleMuteNotifications)
        await fulfillment(of: [expectation])
        
        XCTAssertFalse(context.viewState.isProcessingMuteToggleAction)
        
        let deferred = deferFulfillment(context.$viewState) { state in
            switch state.notificationSettingsState {
            case .loaded(settings: let settings):
                return settings.mode == .mute
            default:
                return false
            }
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        if case .loaded(let newNotificationSettingsState) = viewModel.state.notificationSettingsState {
            XCTAssertFalse(newNotificationSettingsState.isDefault)
            XCTAssertEqual(newNotificationSettingsState.mode, .mute)
        } else {
            XCTFail("invalid state")
        }
    }
    
    func testUnmuteTapped() async throws {
        try await testNotificationRoomMuted()
        
        let expectation = expectation(description: #function)
        notificationSettingsProxyMock.unmuteRoomRoomIdIsEncryptedIsOneToOneClosure = { [weak notificationSettingsProxyMock] _, _, _ in
            notificationSettingsProxyMock?.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .allMessages, isDefault: false))
            expectation.fulfill()
        }
        context.send(viewAction: .processToggleMuteNotifications)
        await fulfillment(of: [expectation])
        
        XCTAssertFalse(context.viewState.isProcessingMuteToggleAction)
        
        let deferred = deferFulfillment(context.$viewState) { state in
            switch state.notificationSettingsState {
            case .loaded(settings: let settings):
                return settings.mode == .allMessages
            default:
                return false
            }
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        if case .loaded(let newNotificationSettingsState) = viewModel.state.notificationSettingsState {
            XCTAssertFalse(newNotificationSettingsState.isDefault)
            XCTAssertEqual(newNotificationSettingsState.mode, .allMessages)
        } else {
            XCTFail("invalid state")
        }
    }
}
