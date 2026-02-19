//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Testing

@MainActor
@Suite
final class HomeScreenViewModelTests {
    var viewModel: HomeScreenViewModelProtocol!
    var context: HomeScreenViewModelType.Context! {
        viewModel.context
    }
    
    var clientProxy: ClientProxyMock!
    var roomSummaryProvider: RoomSummaryProviderMock!
    var appSettings: AppSettings!
    var notificationManager: NotificationManagerMock!
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        ServiceLocator.shared.register(appSettings: appSettings)
    }
    
    deinit {
        AppSettings.resetAllSettings()
    }
    
    @Test
    func selectRoom() async {
        setupViewModel()
        
        let mockRoomID = "mock_room_id"
        var correctResult = false
        var selectedRoomID = ""
        
        viewModel.actions
            .sink { action in
                switch action {
                case .presentRoom(let roomID):
                    correctResult = true
                    selectedRoomID = roomID
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        context.send(viewAction: .selectRoom(roomIdentifier: mockRoomID))
        await Task.yield()
        #expect(correctResult)
        #expect(mockRoomID == selectedRoomID)
    }
    
    @Test
    func tapUserAvatar() async {
        setupViewModel()
        
        var correctResult = false
        
        viewModel.actions
            .sink { action in
                switch action {
                case .presentSettingsScreen:
                    correctResult = true
                default:
                    break
                }
            }
            .store(in: &cancellables)
        
        context.send(viewAction: .showSettings)
        await Task.yield()
        #expect(correctResult)
    }
    
    @Test
    func leaveRoomAlert() async throws {
        setupViewModel()
        
        let mockRoomID = "1"
        
        clientProxy.roomForIdentifierClosure = { _ in .joined(JoinedRoomProxyMock(.init(id: mockRoomID, name: "Some room"))) }
        
        let deferred = deferFulfillment(context.$viewState) { value in
            value.bindings.leaveRoomAlertItem != nil
        }
        
        context.send(viewAction: .leaveRoom(roomIdentifier: mockRoomID))
        
        try await deferred.fulfill()
        
        #expect(context.leaveRoomAlertItem?.roomID == mockRoomID)
    }
    
    @Test
    func leaveRoomError() async throws {
        setupViewModel()
        
        let mockRoomID = "1"
        let room = JoinedRoomProxyMock(.init(id: mockRoomID, name: "Some room"))
        room.leaveRoomClosure = { .failure(.sdkError(ClientProxyMockError.generic)) }
        
        clientProxy.roomForIdentifierClosure = { _ in .joined(room) }
        
        let deferred = deferFulfillment(context.$viewState) { value in
            value.bindings.alertInfo != nil
        }
        
        context.send(viewAction: .confirmLeaveRoom(roomIdentifier: mockRoomID))
        
        try await deferred.fulfill()
        
        #expect(context.alertInfo != nil)
    }
    
    @Test
    func leaveRoomSuccess() async throws {
        setupViewModel()
        
        let mockRoomID = "1"
        
        let room = JoinedRoomProxyMock(.init(id: mockRoomID, name: "Some room"))
        room.leaveRoomClosure = { .success(()) }
        
        clientProxy.roomForIdentifierClosure = { _ in .joined(room) }
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            if case .roomLeft(let roomIdentifier) = action {
                return roomIdentifier == mockRoomID
            }
            return false
        }
        
        context.send(viewAction: .confirmLeaveRoom(roomIdentifier: mockRoomID))
        try await deferred.fulfill()
        #expect(context.alertInfo == nil)
    }
    
    @Test
    func showRoomDetails() async {
        setupViewModel()
        
        let mockRoomID = "1"
        var correctResult = false
        viewModel.actions
            .sink { action in
                switch action {
                case .presentRoomDetails(let roomIdentifier):
                    correctResult = roomIdentifier == mockRoomID
                default:
                    break
                }
            }
            .store(in: &cancellables)
        context.send(viewAction: .showRoomDetails(roomIdentifier: mockRoomID))
        await Task.yield()
        #expect(context.alertInfo == nil)
        #expect(correctResult)
    }
    
    @Test
    func filters() async throws {
        setupViewModel()
        
        context.filtersState.activateFilter(.people)
        try await Task.sleep(for: .milliseconds(100))
        #expect(roomSummaryProvider.roomListPublisher.value.count == 2)
        #expect(roomSummaryProvider.roomListPublisher.value.first?.name == "Foundation and Earth")
    }
    
    @Test
    func search() async throws {
        setupViewModel()
        
        context.isSearchFieldFocused = true
        context.searchQuery = "lude to Found"
        try await Task.sleep(for: .milliseconds(100))
        #expect(roomSummaryProvider.roomListPublisher.value.first?.name == "Prelude to Foundation")
        #expect(roomSummaryProvider.roomListPublisher.value.count == 1)
    }
    
    @Test
    func filtersEmptyState() async throws {
        setupViewModel()
        
        context.filtersState.activateFilter(.people)
        context.filtersState.activateFilter(.favourites)
        try await Task.sleep(for: .milliseconds(100))
        #expect(context.viewState.shouldShowEmptyFilterState)
        context.isSearchFieldFocused = true
        #expect(!context.viewState.shouldShowEmptyFilterState)
    }
    
    @Test
    func setUpRecoveryBannerState() async throws {
        // Given a view model without a visible security banner.
        let securityStateStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .verified, recoveryState: .unknown))
        setupViewModel(securityStatePublisher: securityStateStateSubject.asCurrentValuePublisher())
        #expect(context.viewState.securityBannerMode == .none)
        
        // When the recovery state comes through as disabled.
        var deferred = deferFulfillment(context.$viewState) { $0.requiresExtraAccountSetup == true }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .disabled))
        try await deferred.fulfill()
        
        // Then the banner should be shown to set up recovery.
        #expect(context.viewState.securityBannerMode == .show(.setUpRecovery))
        
        // When the recovery is enabled.
        deferred = deferFulfillment(context.$viewState) { $0.requiresExtraAccountSetup == false }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .enabled))
        try await deferred.fulfill()
        
        // Then the banner should no longer be shown.
        #expect(context.viewState.securityBannerMode == .none)
    }
    
    @Test
    func dismissSetUpRecoveryBannerState() async throws {
        // Given a view model with the setup recovery banner shown.
        let securityStateStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .verified, recoveryState: .unknown))
        setupViewModel(securityStatePublisher: securityStateStateSubject.asCurrentValuePublisher())
        var deferred = deferFulfillment(context.$viewState) { $0.securityBannerMode == .show(.setUpRecovery) }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .disabled))
        try await deferred.fulfill()
        
        // When the banner is dismissed.
        deferred = deferFulfillment(context.$viewState) { $0.securityBannerMode == .dismissed }
        context.send(viewAction: .skipRecoveryKeyConfirmation)
        
        // Then the banner should no longer be shown.
        try await deferred.fulfill()
        
        // And when the recovery state comes through a second time the banner should still not be shown.
        let failure = deferFailure(context.$viewState, timeout: .seconds(1)) { $0.securityBannerMode != .dismissed }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .disabled))
        try await failure.fulfill()
    }
    
    @Test
    func outOfSyncRecoveryBannerState() async throws {
        // Given a view model without a visible security banner.
        let securityStateStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .verified, recoveryState: .unknown))
        setupViewModel(securityStatePublisher: securityStateStateSubject.asCurrentValuePublisher())
        #expect(context.viewState.securityBannerMode == .none)
        
        // When the recovery state comes through as incomplete.
        var deferred = deferFulfillment(context.$viewState) { $0.requiresExtraAccountSetup == true }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .incomplete))
        try await deferred.fulfill()
        
        // Then the banner should be shown for out of sync recovery.
        #expect(context.viewState.securityBannerMode == .show(.recoveryOutOfSync))
        
        // When the recovery is enabled.
        deferred = deferFulfillment(context.$viewState) { $0.requiresExtraAccountSetup == false }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .enabled))
        try await deferred.fulfill()
        
        // Then the banner should no longer be shown.
        #expect(context.viewState.securityBannerMode == .none)
    }
    
    @Test
    func inviteUnreadBadge() async throws {
        setupViewModel(invites: .rooms)
        var invites = context.viewState.rooms.invites
        #expect(invites.count == 2)
        
        for invite in invites {
            #expect(invite.badges.isDotShown)
        }
        
        let deferred = deferFulfillment(context.$viewState) { state in
            state.rooms.contains { room in
                room.roomID == invites[0].roomID && room.badges.isDotShown == false
            }
        }
        appSettings.seenInvites = Set(invites.compactMap(\.roomID))
        try await deferred.fulfill()
        invites = context.viewState.rooms.invites
        
        for invite in invites {
            #expect(!invite.badges.isDotShown)
        }
    }
    
    @Test
    func acceptInvite() async throws {
        setupViewModel(invites: .rooms)
        
        let invitedRoomIDs = context.viewState.rooms.invites.compactMap(\.roomID)
        appSettings.seenInvites = Set(invitedRoomIDs)
        #expect(invitedRoomIDs.count == 2)
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .presentRoom(roomIdentifier: invitedRoomIDs[0]) }
        context.send(viewAction: .acceptInvite(roomIdentifier: invitedRoomIDs[0]))
        try await deferred.fulfill()
        
        #expect(appSettings.seenInvites == [invitedRoomIDs[1]])
        #expect(!notificationManager.removeDeliveredMessageNotificationsForCalled, "The notification will be dismissed when opening the room.")
    }
    
    @Test
    func acceptSpaceInvite() async throws {
        setupViewModel(invites: .spaces)
        
        let invitedRoomIDs = context.viewState.rooms.invites.compactMap(\.roomID)
        appSettings.seenInvites = Set(invitedRoomIDs)
        #expect(invitedRoomIDs.count == 2)
        
        let deferred = deferFulfillment(viewModel.actions) {
            $0 == .presentSpace(SpaceRoomListProxyMock(.init(spaceServiceRoom: SpaceServiceRoom.mock(id: invitedRoomIDs[0], isSpace: true))))
        }
        context.send(viewAction: .acceptInvite(roomIdentifier: invitedRoomIDs[0]))
        try await deferred.fulfill()
        
        #expect(appSettings.seenInvites == [invitedRoomIDs[1]])
        #expect(!notificationManager.removeDeliveredMessageNotificationsForCalled, "The notification will be dismissed when opening the room.")
    }
    
    @Test
    func declineInvite() async throws {
        setupViewModel(invites: .rooms)
        let invitedRoomIDs = context.viewState.rooms.invites.compactMap(\.roomID)
        appSettings.seenInvites = Set(invitedRoomIDs)
        #expect(invitedRoomIDs.count == 2)
        
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.send(viewAction: .declineInvite(roomIdentifier: invitedRoomIDs[0]))
        try await deferred.fulfill()
        
        var rejectCalled = false
        clientProxy.roomForIdentifierClosure = { _ in
            let roomProxy = InvitedRoomProxyMock(.init())
            roomProxy.rejectInvitationClosure = {
                rejectCalled = true
                return .success(())
            }
            
            return .invited(roomProxy)
        }
        context.viewState.bindings.alertInfo?.verticalButtons?[0].action?()
        
        // Wait for the async action to complete
        try await Task.sleep(for: .milliseconds(100))
        #expect(rejectCalled)
        
        #expect(appSettings.seenInvites == [invitedRoomIDs[1]])
        #expect(notificationManager.removeDeliveredMessageNotificationsForCalled)
        #expect(notificationManager.removeDeliveredMessageNotificationsForReceivedInvocations == [invitedRoomIDs[0]])
    }
    
    @Test
    func declineAndBlockInvite() async throws {
        setupViewModel(invites: .rooms)
        let invitedRoomIDs = context.viewState.rooms.invites.compactMap(\.roomID)
        appSettings.seenInvites = Set(invitedRoomIDs)
        #expect(invitedRoomIDs.count == 2)
        
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.send(viewAction: .declineInvite(roomIdentifier: invitedRoomIDs[0]))
        try await deferred.fulfill()
        
        let deferredAction = deferFulfillment(viewModel.actions) { $0 == .presentDeclineAndBlock(userID: RoomMemberProxyMock.mockCharlie.userID, roomID: invitedRoomIDs[0]) }
        context.viewState.bindings.alertInfo?.secondaryButton?.action?()
        try await deferredAction.fulfill()
    }
    
    @Test
    func newSoundBanner() {
        appSettings.hasSeenNewSoundBanner = false
        
        setupViewModel()
        #expect(context.viewState.shouldShowBanner)
        #expect(context.viewState.shouldShowNewSoundBanner)
        
        context.send(viewAction: .dismissNewSoundBanner)
        #expect(!context.viewState.shouldShowBanner)
        #expect(!context.viewState.shouldShowNewSoundBanner)
        #expect(appSettings.hasSeenNewSoundBanner)
    }
    
    // MARK: - Helpers
    
    enum InviteType { case rooms, spaces }
    
    private func setupViewModel(securityStatePublisher: CurrentValuePublisher<SessionSecurityState, Never>? = nil, invites: InviteType? = nil) {
        cancellables.removeAll()
        
        var rooms: [RoomSummary] = .mockRooms
        
        switch invites {
        case .rooms:
            rooms += .mockInvites
        case .spaces:
            rooms += .mockSpaceInvites
        case nil:
            break
        }
        
        roomSummaryProvider = RoomSummaryProviderMock(.init(state: .loaded(rooms)))
        
        clientProxy = ClientProxyMock(.init(userID: "@mock:client.com",
                                            roomSummaryProvider: roomSummaryProvider))
        
        clientProxy.joinRoomViaReturnValue = .success(())
        clientProxy.joinRoomAliasReturnValue = .success(())
        
        switch invites {
        case .rooms:
            clientProxy.roomForIdentifierClosure = { roomID in .invited(InvitedRoomProxyMock(.init(id: roomID))) }
        case .spaces:
            clientProxy.roomForIdentifierClosure = { spaceID in .invited(InvitedRoomProxyMock(.init(id: spaceID, isSpace: true))) }
            
            let spaceServiceProxy = SpaceServiceProxyMock(.init())
            spaceServiceProxy.spaceRoomListSpaceIDClosure = { spaceID in
                .success(SpaceRoomListProxyMock(.init(spaceServiceRoom: SpaceServiceRoom.mock(id: spaceID, isSpace: true))))
            }
            clientProxy.underlyingSpaceService = spaceServiceProxy
        case nil:
            break
        }
        
        let userSession = UserSessionMock(.init(clientProxy: clientProxy))
        if let securityStatePublisher {
            userSession.sessionSecurityStatePublisher = securityStatePublisher
        }
        
        notificationManager = NotificationManagerMock()
        
        viewModel = HomeScreenViewModel(userSession: userSession,
                                        selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                        appSettings: appSettings,
                                        analyticsService: ServiceLocator.shared.analytics,
                                        notificationManager: notificationManager,
                                        userIndicatorController: ServiceLocator.shared.userIndicatorController)
    }
}

private extension [HomeScreenRoom] {
    var invites: [HomeScreenRoom] {
        filter { room in
            if case .invite = room.type {
                true
            } else {
                false
            }
        }
    }
}

extension HomeScreenViewModelAction: @retroactive Equatable {
    public static func == (lhs: HomeScreenViewModelAction, rhs: HomeScreenViewModelAction) -> Bool {
        switch (lhs, rhs) {
        case (.presentRoom(let lhsID), .presentRoom(let rhsID)):
            lhsID == rhsID
        case (.presentRoomDetails(let lhsID), .presentRoomDetails(let rhsID)):
            lhsID == rhsID
        case (.presentReportRoom(let lhsID), .presentReportRoom(let rhsID)):
            lhsID == rhsID
        case (.presentDeclineAndBlock(let lhsUserID, let lhsRoomID), .presentDeclineAndBlock(let rhsUserID, let rhsRoomID)):
            lhsUserID == rhsUserID && lhsRoomID == rhsRoomID
        case (.presentSpace(let lhsSpaceRoomListProxy), .presentSpace(let rhsSpaceRoomListProxy)):
            lhsSpaceRoomListProxy.id == rhsSpaceRoomListProxy.id
        case (.roomLeft(let lhsID), .roomLeft(let rhsID)):
            lhsID == rhsID
        case (.transferOwnership(let lhsID), .transferOwnership(let rhsID)):
            lhsID == rhsID
        case (.presentSecureBackupSettings, .presentSecureBackupSettings):
            true
        case (.presentRecoveryKeyScreen, .presentRecoveryKeyScreen):
            true
        case (.presentEncryptionResetScreen, .presentEncryptionResetScreen):
            true
        case (.presentSettingsScreen, .presentSettingsScreen):
            true
        case (.presentFeedbackScreen, .presentFeedbackScreen):
            true
        case (.presentStartChatScreen, .presentStartChatScreen):
            true
        case (.presentGlobalSearch, .presentGlobalSearch):
            true
        case (.logout, .logout):
            true
        default:
            false
        }
    }
}
