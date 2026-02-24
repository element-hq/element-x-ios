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
import Testing

@Suite
@MainActor
struct RoomDetailsScreenViewModelTests {
    var viewModel: RoomDetailsScreenViewModel!
    var roomProxyMock: JoinedRoomProxyMock!
    var notificationSettingsProxyMock: NotificationSettingsProxyMock!
    var context: RoomDetailsScreenViewModelType.Context {
        viewModel.context
    }

    var cancellables = Set<AnyCancellable>()
    
    init() {
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
    
    @Test
    mutating func leaveRoomTappedWhenPublic() async throws {
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
        
        #expect(context.viewState.bindings.leaveRoomAlertItem?.state == .public)
        #expect(context.viewState.bindings.leaveRoomAlertItem?.subtitle == L10n.leaveRoomAlertSubtitle)
    }
    
    @Test
    mutating func leaveRoomTappedWhenRoomNotPublic() async throws {
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
        
        #expect(context.viewState.bindings.leaveRoomAlertItem?.state == .private)
        #expect(context.viewState.bindings.leaveRoomAlertItem?.subtitle == L10n.leaveRoomAlertPrivateSubtitle)
    }
    
    @Test
    mutating func leaveRoomTappedWithLessThanTwoMembers() {
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
        #expect(context.leaveRoomAlertItem?.state == .empty)
        #expect(context.leaveRoomAlertItem?.subtitle == L10n.leaveRoomAlertEmptySubtitle)
    }
    
    @Test
    func leaveRoomSuccess() async throws {
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
        
        #expect(roomProxyMock.leaveRoomCallsCount == 1)
    }
    
    @Test
    func leaveRoomError() async throws {
        try await confirmation("leaveRoomError") { confirm in
            roomProxyMock.leaveRoomClosure = {
                defer {
                    confirm()
                }
                return .failure(.sdkError(ClientProxyMockError.generic))
            }
            
            let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }
            context.send(viewAction: .confirmLeave)
            try await deferred.fulfill()
        }
        
        #expect(roomProxyMock.leaveRoomCallsCount == 1)
    }
    
    @Test
    mutating func initialDMDetailsState() async throws {
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
        
        #expect(context.viewState.dmRecipientInfo?.member == RoomMemberDetails(withProxy: recipient))
    }
    
    @Test
    mutating func ignoreSuccess() async throws {
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
        
        #expect(context.viewState.dmRecipientInfo?.member == RoomMemberDetails(withProxy: recipient))
                                    
        let deferredProcessing = deferFulfillment(viewModel.context.observe(\.viewState.isProcessingIgnoreRequest),
                                                  transitionValues: [false, true, false])
        
        context.send(viewAction: .ignoreConfirmed)
        
        try await deferredProcessing.fulfill()
        
        #expect(context.viewState.dmRecipientInfo?.member.isIgnored == true)
    }
    
    @Test
    mutating func ignoreFailure() async throws {
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
        
        #expect(context.viewState.dmRecipientInfo?.member == RoomMemberDetails(withProxy: recipient))
        
        let deferredProcessing = deferFulfillment(viewModel.context.observe(\.viewState.isProcessingIgnoreRequest),
                                                  transitionValues: [false, true, false])
        
        context.send(viewAction: .ignoreConfirmed)
        
        try await deferredProcessing.fulfill()
        
        #expect(context.viewState.dmRecipientInfo?.member.isIgnored == false)
        #expect(context.alertInfo != nil)
    }
    
    @Test
    mutating func unignoreSuccess() async throws {
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
        
        #expect(context.viewState.dmRecipientInfo?.member == RoomMemberDetails(withProxy: recipient))
        
        let deferredProcessing = deferFulfillment(viewModel.context.observe(\.viewState.isProcessingIgnoreRequest),
                                                  transitionValues: [false, true, false])
        
        context.send(viewAction: .unignoreConfirmed)
                
        try await deferredProcessing.fulfill()
        
        #expect(context.viewState.dmRecipientInfo?.member.isIgnored == false)
    }
    
    @Test
    mutating func unignoreFailure() async throws {
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
        
        #expect(context.viewState.dmRecipientInfo?.member == RoomMemberDetails(withProxy: recipient))
        
        let deferredProcessing = deferFulfillment(viewModel.context.observe(\.viewState.isProcessingIgnoreRequest),
                                                  transitionValues: [false, true, false])
        
        context.send(viewAction: .unignoreConfirmed)
                
        try await deferredProcessing.fulfill()
        
        #expect(context.viewState.dmRecipientInfo?.member.isIgnored == true)
        #expect(context.alertInfo != nil)
    }
    
    @Test
    mutating func cannotInvitePeople() async {
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
        
        #expect(!context.viewState.canInviteUsers)
    }
    
    @Test
    mutating func invitePeople() async {
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
        
        #expect(context.viewState.canInviteUsers)
        
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
        #expect(callbackCorrectlyCalled)
    }
    
    @Test
    mutating func canEditAvatar() async {
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
        
        #expect(context.viewState.canEditRoomAvatar)
        #expect(!context.viewState.canEditRoomName)
        #expect(!context.viewState.canEditRoomTopic)
        #expect(context.viewState.canEditBaseInfo)
    }
    
    @Test
    mutating func canEditName() async {
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
        
        #expect(!context.viewState.canEditRoomAvatar)
        #expect(context.viewState.canEditRoomName)
        #expect(!context.viewState.canEditRoomTopic)
        #expect(context.viewState.canEditBaseInfo)
    }
    
    @Test
    mutating func canEditTopic() async {
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
        
        #expect(!context.viewState.canEditRoomAvatar)
        #expect(!context.viewState.canEditRoomName)
        #expect(context.viewState.canEditRoomTopic)
        #expect(context.viewState.canEditBaseInfo)
    }
    
    @Test
    mutating func cannotEditRoom() async {
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
        
        #expect(!context.viewState.canEditRoomAvatar)
        #expect(!context.viewState.canEditRoomName)
        #expect(!context.viewState.canEditRoomTopic)
        #expect(!context.viewState.canEditBaseInfo)
    }
    
    @Test
    mutating func cannotEditDirectRoom() async {
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
        
        #expect(!context.viewState.canEditBaseInfo)
    }
    
    // MARK: - Notifications
    
    @Test
    mutating func notificationLoadingSettingsFailure() async throws {
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
        #expect(context.viewState.bindings.alertInfo?.id == expectedAlertInfo.id)
        #expect(context.viewState.bindings.alertInfo?.title == expectedAlertInfo.title)
        #expect(context.viewState.bindings.alertInfo?.message == expectedAlertInfo.message)
    }
    
    @Test
    func notificationDefaultMode() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .allMessages, isDefault: true))
        
        let deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { $0.isLoaded }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        #expect(context.viewState.notificationSettingsState.label == "Default")
    }
    
    @Test
    func notificationCustomMode() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .allMessages, isDefault: false))
        
        let deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { $0.isCustom }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        #expect(context.viewState.notificationSettingsState.label == "Custom")
    }
    
    @Test
    func notificationRoomMuted() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mute, isDefault: false))
        
        let deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { $0.isLoaded }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        _ = await context.observe(\.viewState).debounce(for: .milliseconds(100)).first()
        
        #expect(context.viewState.notificationShortcutButtonTitle == L10n.commonUnmute)
        #expect(context.viewState.notificationShortcutButtonIcon == \.notificationsOff)
    }
    
    @Test
    func notificationRoomNotMuted() async throws {
        notificationSettingsProxyMock.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .mentionsAndKeywordsOnly, isDefault: false))
        
        let deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { $0.isLoaded }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        #expect(context.viewState.notificationShortcutButtonTitle == L10n.commonMute)
        #expect(context.viewState.notificationShortcutButtonIcon == \.notifications)
    }
    
    @Test
    func unmuteTappedFailure() async throws {
        try await notificationRoomMuted()
        
        try await confirmation("unmuteTappedFailure") { confirm in
            notificationSettingsProxyMock.unmuteRoomRoomIdIsEncryptedIsOneToOneClosure = { _, _, _ in
                defer {
                    confirm()
                }
                throw NotificationSettingsError.Generic(msg: "unmute error")
            }
            context.send(viewAction: .processToggleMuteNotifications)
            try await deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }.fulfill()
        }
        
        #expect(!context.viewState.isProcessingMuteToggleAction)
        #expect(context.viewState.notificationShortcutButtonTitle == L10n.commonUnmute)
        
        let expectedAlertInfo = AlertInfo(id: RoomDetailsScreenErrorType.alert,
                                          title: L10n.commonError,
                                          message: L10n.screenRoomDetailsErrorUnmuting)
        
        #expect(context.viewState.bindings.alertInfo?.id == expectedAlertInfo.id)
        #expect(context.viewState.bindings.alertInfo?.title == expectedAlertInfo.title)
        #expect(context.viewState.bindings.alertInfo?.message == expectedAlertInfo.message)
    }
    
    @Test
    func muteTappedFailure() async throws {
        try await notificationRoomNotMuted()
        
        try await confirmation("muteTappedFailure") { confirm in
            notificationSettingsProxyMock.setNotificationModeRoomIdModeClosure = { _, _ in
                defer {
                    confirm()
                }
                throw NotificationSettingsError.Generic(msg: "mute error")
            }
            
            let deferred = deferFulfillment(context.observe(\.alertInfo)) { $0 != nil }
            context.send(viewAction: .processToggleMuteNotifications)
            try await deferred.fulfill()
        }
        
        #expect(!context.viewState.isProcessingMuteToggleAction)
        #expect(context.viewState.notificationShortcutButtonTitle == L10n.commonMute)
        
        let expectedAlertInfo = AlertInfo(id: RoomDetailsScreenErrorType.alert,
                                          title: L10n.commonError,
                                          message: L10n.screenRoomDetailsErrorMuting)
        
        #expect(context.viewState.bindings.alertInfo?.id == expectedAlertInfo.id)
        #expect(context.viewState.bindings.alertInfo?.title == expectedAlertInfo.title)
        #expect(context.viewState.bindings.alertInfo?.message == expectedAlertInfo.message)
    }
    
    @Test
    func muteTapped() async throws {
        try await notificationRoomNotMuted()
        
        try await confirmation("muteTapped") { confirm in
            notificationSettingsProxyMock.setNotificationModeRoomIdModeClosure = { [weak notificationSettingsProxyMock] _, mode in
                notificationSettingsProxyMock?.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: mode, isDefault: false))
                confirm()
            }
            
            let deferred = deferFulfillment(context.observe(\.viewState.isProcessingMuteToggleAction),
                                            transitionValues: [false, true, false])
            context.send(viewAction: .processToggleMuteNotifications)
            try await deferred.fulfill()
        }
        
        let deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { state in
            switch state {
            case .loaded(settings: let settings): settings.mode == .mute
            default: false
            }
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        if case .loaded(let newNotificationSettingsState) = viewModel.state.notificationSettingsState {
            #expect(!newNotificationSettingsState.isDefault)
            #expect(newNotificationSettingsState.mode == .mute)
        } else {
            Issue.record("invalid state")
        }
    }
    
    @Test
    func unmuteTapped() async throws {
        try await notificationRoomMuted()
        
        try await confirmation("unmuteTapped") { confirm in
            notificationSettingsProxyMock.unmuteRoomRoomIdIsEncryptedIsOneToOneClosure = { [weak notificationSettingsProxyMock] _, _, _ in
                notificationSettingsProxyMock?.getNotificationSettingsRoomIdIsEncryptedIsOneToOneReturnValue = RoomNotificationSettingsProxyMock(with: .init(mode: .allMessages, isDefault: false))
                confirm()
            }
            
            let deferred = deferFulfillment(context.observe(\.viewState.isProcessingMuteToggleAction),
                                            transitionValues: [false, true, false])
            context.send(viewAction: .processToggleMuteNotifications)
            try await deferred.fulfill()
        }
        
        let deferred = deferFulfillment(context.observe(\.viewState.notificationSettingsState)) { state in
            switch state {
            case .loaded(settings: let settings): settings.mode == .allMessages
            default: false
            }
        }
        
        notificationSettingsProxyMock.callbacks.send(.settingsDidChange)
        try await deferred.fulfill()
        
        if case .loaded(let newNotificationSettingsState) = viewModel.state.notificationSettingsState {
            #expect(!newNotificationSettingsState.isDefault)
            #expect(newNotificationSettingsState.mode == .allMessages)
        } else {
            Issue.record("invalid state")
        }
    }
    
    // MARK: - Knock Requests
    
    @Test
    mutating func knockRequestsCounter() async throws {
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
    
    @Test
    mutating func knockRequestsCounterIsLoading() async throws {
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
    
    @Test
    mutating func knockRequestsCounterIsNotShownIfNoPermissions() async throws {
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
    
    @Test
    mutating func knockRequestsCounterIsNotShownIfDM() async throws {
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
    
    @Test
    mutating func historySharingPillDoesNotAppearIfFeatureFlagNotSet() async throws {
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
                                             timeout: .seconds(1),
                                             message: "The pill should not be shown as the feature flag is not set") { state in
            state.details.historySharingState != nil
        }
        try await deferredInvisible.fulfill()
    }
    
    @Test
    mutating func historySharingPillDisplayedIfHistoryVisibilityShared() async throws {
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
