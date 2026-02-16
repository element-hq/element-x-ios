//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import AsyncAlgorithms
import Combine
@testable import ElementX
import MatrixRustSDK
import SwiftUI
import XCTest

@MainActor
class RoomDetailsScreenViewModelTests: XCTestCase {
    var viewModel: RoomDetailsScreenViewModel!
    var roomProxyMock: JoinedRoomProxyMock!
    var notificationSettingsProxyMock: NotificationSettingsProxyMock!
    var context: RoomDetailsScreenViewModelType.Context {
        viewModel.context
    }

    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        AppSettings.resetAllSettings()
        cancellables.removeAll()
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test"))
        notificationSettingsProxyMock = NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration())
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: notificationSettingsProxyMock,
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
    }
    
    func testLeaveRoomTappedWhenPublic() async throws {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", members: mockedMembers, joinRule: .public))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.leaveRoomAlertItem)) { $0 != nil }
        
        context.send(viewAction: .processTapLeave)
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.bindings.leaveRoomAlertItem?.state, .public)
        XCTAssertEqual(context.viewState.bindings.leaveRoomAlertItem?.subtitle, L10n.leaveRoomAlertSubtitle)
    }
    
    func testLeaveRoomTappedWhenRoomNotPublic() async throws {
        let mockedMembers: [RoomMemberProxyMock] = [.mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.leaveRoomAlertItem)) { $0 != nil }
        
        context.send(viewAction: .processTapLeave)
        
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.bindings.leaveRoomAlertItem?.state, .private)
        XCTAssertEqual(context.viewState.bindings.leaveRoomAlertItem?.subtitle, L10n.leaveRoomAlertPrivateSubtitle)
    }
    
    func testLeaveRoomTappedWithLessThanTwoMembers() {
        let mockedMembers: [RoomMemberProxyMock] = [.mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
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
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        let deferred = deferFulfillment(viewModel.context.observe(\.viewState.dmRecipientInfo)) { $0 != nil }
        
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.dmRecipientInfo?.member, RoomMemberDetails(withProxy: recipient))
    }
    
    func testIgnoreSuccess() async throws {
        let recipient = RoomMemberProxyMock.mockDan
        
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        let deferredRecipient = deferFulfillment(viewModel.context.observe(\.viewState.dmRecipientInfo)) { $0 != nil }
        
        try await deferredRecipient.fulfill()
        
        XCTAssertEqual(context.viewState.dmRecipientInfo?.member, RoomMemberDetails(withProxy: recipient))
                                    
        let deferredProcessing = deferFulfillment(viewModel.context.observe(\.viewState.isProcessingIgnoreRequest),
                                                  transitionValues: [false, true, false])
        
        context.send(viewAction: .ignoreConfirmed)
        
        try await deferredProcessing.fulfill()
        
        XCTAssert(context.viewState.dmRecipientInfo?.member.isIgnored == true)
    }
    
    func testIgnoreFailure() async throws {
        let recipient = RoomMemberProxyMock.mockDan
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        let clientProxy = ClientProxyMock(.init())
        clientProxy.ignoreUserReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        let deferredRecipient = deferFulfillment(viewModel.context.observe(\.viewState.dmRecipientInfo)) { $0 != nil }
        
        try await deferredRecipient.fulfill()
        
        XCTAssertEqual(context.viewState.dmRecipientInfo?.member, RoomMemberDetails(withProxy: recipient))
        
        let deferredProcessing = deferFulfillment(viewModel.context.observe(\.viewState.isProcessingIgnoreRequest),
                                                  transitionValues: [false, true, false])
        
        context.send(viewAction: .ignoreConfirmed)
        
        try await deferredProcessing.fulfill()
        
        XCTAssert(context.viewState.dmRecipientInfo?.member.isIgnored == false)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testUnignoreSuccess() async throws {
        let recipient = RoomMemberProxyMock.mockIgnored
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        let deferredRecipient = deferFulfillment(viewModel.context.observe(\.viewState.dmRecipientInfo)) { $0 != nil }
        
        try await deferredRecipient.fulfill()
        
        XCTAssertEqual(context.viewState.dmRecipientInfo?.member, RoomMemberDetails(withProxy: recipient))
        
        let deferredProcessing = deferFulfillment(viewModel.context.observe(\.viewState.isProcessingIgnoreRequest),
                                                  transitionValues: [false, true, false])
        
        context.send(viewAction: .unignoreConfirmed)
                
        try await deferredProcessing.fulfill()
        
        XCTAssert(context.viewState.dmRecipientInfo?.member.isIgnored == false)
    }
    
    func testUnignoreFailure() async throws {
        let recipient = RoomMemberProxyMock.mockIgnored
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, recipient]
        let clientProxy = ClientProxyMock(.init())
        clientProxy.unignoreUserReturnValue = .failure(.sdkError(ClientProxyMockError.generic))
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: true, isEncrypted: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init(clientProxy: clientProxy)),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        let deferredRecipient = deferFulfillment(viewModel.context.observe(\.viewState.dmRecipientInfo)) { $0 != nil }
        
        try await deferredRecipient.fulfill()
        
        XCTAssertEqual(context.viewState.dmRecipientInfo?.member, RoomMemberDetails(withProxy: recipient))
        
        let deferredProcessing = deferFulfillment(viewModel.context.observe(\.viewState.isProcessingIgnoreRequest),
                                                  transitionValues: [false, true, false])
        
        context.send(viewAction: .unignoreConfirmed)
                
        try await deferredProcessing.fulfill()
        
        XCTAssert(context.viewState.dmRecipientInfo?.member.isIgnored == true)
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testCannotInvitePeople() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test",
                                                  members: mockedMembers,
                                                  joinRule: .public,
                                                  powerLevelsConfiguration: .init(canUserInvite: false)))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.observe(\.viewState).debounce(for: .milliseconds(100)).first()
        
        XCTAssertFalse(context.viewState.canInviteUsers)
    }
    
    func testInvitePeople() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", members: mockedMembers, joinRule: .public))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.observe(\.viewState).debounce(for: .milliseconds(100)).first()
        
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
        
        let configuration = JoinedRoomProxyMockConfiguration(name: "Test",
                                                             isDirect: false,
                                                             members: mockedMembers)
        
        roomProxyMock = JoinedRoomProxyMock(configuration)
        
        let powerLevelsProxyMock = RoomPowerLevelsProxyMock(configuration: .init())
        powerLevelsProxyMock.canUserUserIDSendStateEventClosure = { _, event in
            .success(event == .roomAvatar)
        }
        powerLevelsProxyMock.canOwnUserSendStateEventClosure = { event in
            event == .roomAvatar
        }
        roomProxyMock.powerLevelsReturnValue = .success(powerLevelsProxyMock)
        
        let roomInfoProxyMock = RoomInfoProxyMock(configuration)
        roomInfoProxyMock.powerLevels = powerLevelsProxyMock
        roomProxyMock.infoPublisher = CurrentValueSubject(roomInfoProxyMock).asCurrentValuePublisher()
        
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.observe(\.viewState).debounce(for: .milliseconds(100)).first()
        
        XCTAssertTrue(context.viewState.canEditRoomAvatar)
        XCTAssertFalse(context.viewState.canEditRoomName)
        XCTAssertFalse(context.viewState.canEditRoomTopic)
        XCTAssertTrue(context.viewState.canEditBaseInfo)
    }
    
    func testCanEditName() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockBob, .mockAlice]
        
        let configuration = JoinedRoomProxyMockConfiguration(name: "Test",
                                                             isDirect: false,
                                                             members: mockedMembers)
        
        roomProxyMock = JoinedRoomProxyMock(configuration)
        
        let powerLevelsProxyMock = RoomPowerLevelsProxyMock(configuration: .init())
        powerLevelsProxyMock.canUserUserIDSendStateEventClosure = { _, event in
            .success(event == .roomName)
        }
        powerLevelsProxyMock.canOwnUserSendStateEventClosure = { event in
            event == .roomName
        }
        roomProxyMock.powerLevelsReturnValue = .success(powerLevelsProxyMock)
        
        let roomInfoProxyMock = RoomInfoProxyMock(configuration)
        roomInfoProxyMock.powerLevels = powerLevelsProxyMock
        roomProxyMock.infoPublisher = CurrentValueSubject(roomInfoProxyMock).asCurrentValuePublisher()
        
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.observe(\.viewState).debounce(for: .milliseconds(100)).first()
        
        XCTAssertFalse(context.viewState.canEditRoomAvatar)
        XCTAssertTrue(context.viewState.canEditRoomName)
        XCTAssertFalse(context.viewState.canEditRoomTopic)
        XCTAssertTrue(context.viewState.canEditBaseInfo)
    }
    
    func testCanEditTopic() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockBob, .mockAlice]
        
        let configuration = JoinedRoomProxyMockConfiguration(name: "Test",
                                                             isDirect: false,
                                                             members: mockedMembers)
        
        roomProxyMock = JoinedRoomProxyMock(configuration)
        
        let powerLevelsProxyMock = RoomPowerLevelsProxyMock(configuration: .init())
        powerLevelsProxyMock.canUserUserIDSendStateEventClosure = { _, event in
            .success(event == .roomTopic)
        }
        powerLevelsProxyMock.canOwnUserSendStateEventClosure = { event in
            event == .roomTopic
        }
        roomProxyMock.powerLevelsReturnValue = .success(powerLevelsProxyMock)
        
        let roomInfoProxyMock = RoomInfoProxyMock(configuration)
        roomInfoProxyMock.powerLevels = powerLevelsProxyMock
        roomProxyMock.infoPublisher = CurrentValueSubject(roomInfoProxyMock).asCurrentValuePublisher()
        
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.observe(\.viewState).debounce(for: .milliseconds(100)).first()
        
        XCTAssertFalse(context.viewState.canEditRoomAvatar)
        XCTAssertFalse(context.viewState.canEditRoomName)
        XCTAssertTrue(context.viewState.canEditRoomTopic)
        XCTAssertTrue(context.viewState.canEditBaseInfo)
    }
    
    func testCannotEditRoom() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: false, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.observe(\.viewState).debounce(for: .milliseconds(100)).first()
        
        XCTAssertFalse(context.viewState.canEditRoomAvatar)
        XCTAssertFalse(context.viewState.canEditRoomName)
        XCTAssertFalse(context.viewState.canEditRoomTopic)
        XCTAssertFalse(context.viewState.canEditBaseInfo)
    }
    
    func testCannotEditDirectRoom() async {
        let mockedMembers: [RoomMemberProxyMock] = [.mockMeAdmin, .mockBob, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: true, members: mockedMembers))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: NotificationSettingsProxyMock(with: NotificationSettingsProxyMockConfiguration()),
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        _ = await context.observe(\.viewState).debounce(for: .milliseconds(100)).first()
        
        XCTAssertFalse(context.viewState.canEditBaseInfo)
    }
    
    // MARK: - Notifications
    
    func testNotificationLoadingSettingsFailure() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneThrowableError = NotificationSettingsError.Generic(msg: "error")
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: notificationSettingsProxyMock,
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        var deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { $0.isError }
        
        try await deferred.fulfill()
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        
        deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { $0.isError }
        
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
        
        let deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { $0.isLoaded }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.notificationSettingsState.label, "Default")
    }
    
    func testNotificationCustomMode() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .allMessages, isDefault: false))
        
        let deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { $0.isCustom }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        XCTAssertEqual(context.viewState.notificationSettingsState.label, "Custom")
    }
    
    func testNotificationRoomMuted() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mute, isDefault: false))
        
        let deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { $0.isLoaded }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        _ = await context.observe(\.viewState).debounce(for: .milliseconds(100)).first()
        
        XCTAssertEqual(context.viewState.notificationShortcutButtonTitle, L10n.commonUnmute)
        XCTAssertEqual(context.viewState.notificationShortcutButtonIcon, \.notificationsOff)
    }
    
    func testNotificationRoomNotMuted() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        
        let deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { $0.isLoaded }
        
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
        
        let deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { state in
            switch state {
            case .loaded(settings: let settings): settings.mode == .mute
            default: false
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
        
        let deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { state in
            switch state {
            case .loaded(settings: let settings): settings.mode == .allMessages
            default: false
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
    
    // MARK: - Knock Requests
    
    func testKnockRequestsCounter() async throws {
        ServiceLocator.shared.settings.knockingEnabled = true
        let mockedRequests: [KnockRequestProxyMock] = [.init(), .init()]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: false, knockRequestsState: .loaded(mockedRequests), joinRule: .knock))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: notificationSettingsProxyMock,
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        let deferred = deferFulfillment(context.observe(\.viewState)) { state in
            state.knockRequestsCount == 2 && state.canSeeKnockingRequests
        }
        try await deferred.fulfill()
        
        let deferredAction = deferFulfillment(viewModel.actions) { $0 == .displayKnockingRequests }
        context.send(viewAction: .processTapRequestsToJoin)
        try await deferredAction.fulfill()
    }
    
    func testKnockRequestsCounterIsLoading() async throws {
        ServiceLocator.shared.settings.knockingEnabled = true
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: false, knockRequestsState: .loading, joinRule: .knock))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: notificationSettingsProxyMock,
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        let deferred = deferFulfillment(context.observe(\.viewState)) { state in
            state.knockRequestsCount == 0 && state.canSeeKnockingRequests
        }
        
        try await deferred.fulfill()
    }
    
    func testKnockRequestsCounterIsNotShownIfNoPermissions() async throws {
        ServiceLocator.shared.settings.knockingEnabled = true
        let mockedRequests: [KnockRequestProxyMock] = [.init(), .init()]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test",
                                                  isDirect: false,
                                                  knockRequestsState: .loaded(mockedRequests),
                                                  joinRule: .knock,
                                                  powerLevelsConfiguration: .init(canUserInvite: false)))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: notificationSettingsProxyMock,
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        let deferred = deferFulfillment(context.observe(\.viewState)) { state in
            state.knockRequestsCount == 2 &&
                state.dmRecipientInfo == nil &&
                !state.canSeeKnockingRequests &&
                !state.canInviteUsers
        }
        
        try await deferred.fulfill()
    }
    
    func testKnockRequestsCounterIsNotShownIfDM() async throws {
        ServiceLocator.shared.settings.knockingEnabled = true
        let mockedRequests: [KnockRequestProxyMock] = [.init(), .init()]
        let mockedMembers: [RoomMemberProxyMock] = [.mockMe, .mockAlice]
        roomProxyMock = JoinedRoomProxyMock(.init(name: "Test", isDirect: true, members: mockedMembers, knockRequestsState: .loaded(mockedRequests), joinRule: .knock))
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: notificationSettingsProxyMock,
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        let deferred = deferFulfillment(context.observe(\.viewState)) { state in
            state.knockRequestsCount == 2 &&
                !state.canSeeKnockingRequests &&
                state.dmRecipientInfo != nil &&
                state.canInviteUsers
        }
        
        try await deferred.fulfill()
    }
    
    // MARK: - History Sharing
    
    func testHistorySharingPillDoesNotAppearIfFeatureFlagNotSet() async throws {
        ServiceLocator.shared.settings.enableKeyShareOnInvite = false
        
        let configuration = JoinedRoomProxyMockConfiguration(historyVisibility: .shared)
        let infoSubject = CurrentValueSubject<RoomInfoProxyProtocol, Never>(RoomInfoProxyMock(configuration))
        let roomProxyMock = JoinedRoomProxyMock(configuration)
        roomProxyMock.underlyingInfoPublisher = infoSubject.asCurrentValuePublisher()
        
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: notificationSettingsProxyMock,
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        let deferredInvisible = deferFailure(context.observe(\.viewState),
                                             timeout: 1,
                                             message: "The pill should not be shown as the feature flag is not set") { state in
            state.details.historySharingState != nil
        }
        try await deferredInvisible.fulfill()
    }
    
    func testHistorySharingPillDisplayedIfHistoryVisibilityShared() async throws {
        ServiceLocator.shared.settings.enableKeyShareOnInvite = true
        
        let configuration = JoinedRoomProxyMockConfiguration(historyVisibility: .shared)
        let infoSubject = CurrentValueSubject<RoomInfoProxyProtocol, Never>(RoomInfoProxyMock(configuration))
        let roomProxyMock = JoinedRoomProxyMock(configuration)
        roomProxyMock.underlyingInfoPublisher = infoSubject.asCurrentValuePublisher()
        
        viewModel = RoomDetailsScreenViewModel(roomProxy: roomProxyMock,
                                               userSession: UserSessionMock(.init()),
                                               analyticsService: ServiceLocator.shared.analytics,
                                               userIndicatorController: ServiceLocator.shared.userIndicatorController,
                                               notificationSettingsProxy: notificationSettingsProxyMock,
                                               attributedStringBuilder: AttributedStringBuilder(mentionBuilder: MentionBuilder()),
                                               appSettings: ServiceLocator.shared.settings)
        
        let deferredShared = deferFulfillment(context.observe(\.viewState),
                                              message: "The pill should be shown for rooms with shared history visibility") { state in
            state.details.historySharingState == .shared
        }
        try await deferredShared.fulfill()
    }
}
