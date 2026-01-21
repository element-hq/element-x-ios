//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
import XCTest

@testable import ElementX

@MainActor
class HomeScreenViewModelTests: XCTestCase {
    var viewModel: HomeScreenViewModelProtocol!
    var context: HomeScreenViewModelType.Context! { viewModel.context }
    
    var clientProxy: ClientProxyMock!
    var roomSummaryProvider: RoomSummaryProviderMock!
    var appSettings: AppSettings!
    var notificationManager: NotificationManagerMock!
    
    var cancellables = Set<AnyCancellable>()
    
    override func setUp() {
        cancellables.removeAll()
        
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        ServiceLocator.shared.register(appSettings: appSettings)
    }
    
    override func tearDown() {
        AppSettings.resetAllSettings()
    }
    
    func testSelectRoom() async throws {
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
        XCTAssert(correctResult)
        XCTAssertEqual(mockRoomID, selectedRoomID)
    }

    func testTapUserAvatar() async throws {
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
        XCTAssert(correctResult)
    }
    
    func testLeaveRoomAlert() async throws {
        setupViewModel()
        
        let mockRoomID = "1"
        
        clientProxy.roomForIdentifierClosure = { _ in .joined(JoinedRoomProxyMock(.init(id: mockRoomID, name: "Some room"))) }
        
        let deferred = deferFulfillment(context.$viewState) { value in
            value.bindings.leaveRoomAlertItem != nil
        }
        
        context.send(viewAction: .leaveRoom(roomIdentifier: mockRoomID))
        
        try await deferred.fulfill()
        
        XCTAssertEqual(context.leaveRoomAlertItem?.roomID, mockRoomID)
    }
    
    func testLeaveRoomError() async throws {
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
                
        XCTAssertNotNil(context.alertInfo)
    }
    
    func testLeaveRoomSuccess() async throws {
        setupViewModel()
        
        let mockRoomID = "1"
        var correctResult = false
        let expectation = expectation(description: #function)
        viewModel.actions
            .sink { action in
                switch action {
                case .roomLeft(let roomIdentifier):
                    correctResult = roomIdentifier == mockRoomID
                default:
                    break
                }
                expectation.fulfill()
            }
            .store(in: &cancellables)
        let room = JoinedRoomProxyMock(.init(id: mockRoomID, name: "Some room"))
        room.leaveRoomClosure = { .success(()) }
        
        clientProxy.roomForIdentifierClosure = { _ in .joined(room) }
        
        context.send(viewAction: .confirmLeaveRoom(roomIdentifier: mockRoomID))
        await fulfillment(of: [expectation])
        XCTAssertNil(context.alertInfo)
        XCTAssertTrue(correctResult)
    }
    
    func testShowRoomDetails() async throws {
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
        XCTAssertNil(context.alertInfo)
        XCTAssertTrue(correctResult)
    }
    
    func testFilters() async throws {
        setupViewModel()
        
        context.filtersState.activateFilter(.people)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(roomSummaryProvider.roomListPublisher.value.count, 2)
        XCTAssertEqual(roomSummaryProvider.roomListPublisher.value.first?.name, "Foundation and Earth")
    }
    
    func testSearch() async throws {
        setupViewModel()
        
        context.isSearchFieldFocused = true
        context.searchQuery = "lude to Found"
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertEqual(roomSummaryProvider.roomListPublisher.value.first?.name, "Prelude to Foundation")
        XCTAssertEqual(roomSummaryProvider.roomListPublisher.value.count, 1)
    }
    
    func testFiltersEmptyState() async throws {
        setupViewModel()
        
        context.filtersState.activateFilter(.people)
        context.filtersState.activateFilter(.favourites)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssertTrue(context.viewState.shouldShowEmptyFilterState)
        context.isSearchFieldFocused = true
        XCTAssertFalse(context.viewState.shouldShowEmptyFilterState)
    }
    
    func testSetUpRecoveryBannerState() async throws {
        // Given a view model without a visible security banner.
        let securityStateStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .verified, recoveryState: .unknown))
        setupViewModel(securityStatePublisher: securityStateStateSubject.asCurrentValuePublisher())
        XCTAssertEqual(context.viewState.securityBannerMode, .none)
        
        // When the recovery state comes through as disabled.
        var deferred = deferFulfillment(context.$viewState) { $0.requiresExtraAccountSetup == true }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .disabled))
        try await deferred.fulfill()
        
        // Then the banner should be shown to set up recovery.
        XCTAssertEqual(context.viewState.securityBannerMode, .show(.setUpRecovery))
        
        // When the recovery is enabled.
        deferred = deferFulfillment(context.$viewState) { $0.requiresExtraAccountSetup == false }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .enabled))
        try await deferred.fulfill()
        
        // Then the banner should no longer be shown.
        XCTAssertEqual(context.viewState.securityBannerMode, .none)
    }
    
    func testDismissSetUpRecoveryBannerState() async throws {
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
        let failure = deferFailure(context.$viewState, timeout: 1) { $0.securityBannerMode != .dismissed }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .disabled))
        try await failure.fulfill()
    }
    
    func testOutOfSyncRecoveryBannerState() async throws {
        // Given a view model without a visible security banner.
        let securityStateStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .verified, recoveryState: .unknown))
        setupViewModel(securityStatePublisher: securityStateStateSubject.asCurrentValuePublisher())
        XCTAssertEqual(context.viewState.securityBannerMode, .none)
        
        // When the recovery state comes through as incomplete.
        var deferred = deferFulfillment(context.$viewState) { $0.requiresExtraAccountSetup == true }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .incomplete))
        try await deferred.fulfill()
        
        // Then the banner should be shown for out of sync recovery.
        XCTAssertEqual(context.viewState.securityBannerMode, .show(.recoveryOutOfSync))
        
        // When the recovery is enabled.
        deferred = deferFulfillment(context.$viewState) { $0.requiresExtraAccountSetup == false }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .enabled))
        try await deferred.fulfill()
        
        // Then the banner should no longer be shown.
        XCTAssertEqual(context.viewState.securityBannerMode, .none)
    }
    
    func testInviteUnreadBadge() async throws {
        setupViewModel(invites: .rooms)
        var invites = context.viewState.rooms.invites
        XCTAssertEqual(invites.count, 2)
        
        for invite in invites {
            XCTAssertTrue(invite.badges.isDotShown)
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
            XCTAssertFalse(invite.badges.isDotShown)
        }
    }
    
    func testAcceptInvite() async throws {
        setupViewModel(invites: .rooms)
        
        let invitedRoomIDs = context.viewState.rooms.invites.compactMap(\.roomID)
        appSettings.seenInvites = Set(invitedRoomIDs)
        XCTAssertEqual(invitedRoomIDs.count, 2)
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .presentRoom(roomIdentifier: invitedRoomIDs[0]) }
        context.send(viewAction: .acceptInvite(roomIdentifier: invitedRoomIDs[0]))
        try await deferred.fulfill()
        
        XCTAssertEqual(appSettings.seenInvites, [invitedRoomIDs[1]])
        XCTAssertFalse(notificationManager.removeDeliveredMessageNotificationsForCalled, "The notification will be dismissed when opening the room.")
    }
    
    func testAcceptSpaceInvite() async throws {
        setupViewModel(invites: .spaces)
        
        let invitedRoomIDs = context.viewState.rooms.invites.compactMap(\.roomID)
        appSettings.seenInvites = Set(invitedRoomIDs)
        XCTAssertEqual(invitedRoomIDs.count, 2)
        
        let deferred = deferFulfillment(viewModel.actions) {
            $0 == .presentSpace(SpaceRoomListProxyMock(.init(spaceServiceRoom: SpaceServiceRoomMock(.init(id: invitedRoomIDs[0], isSpace: true)))))
        }
        context.send(viewAction: .acceptInvite(roomIdentifier: invitedRoomIDs[0]))
        try await deferred.fulfill()
        
        XCTAssertEqual(appSettings.seenInvites, [invitedRoomIDs[1]])
        XCTAssertFalse(notificationManager.removeDeliveredMessageNotificationsForCalled, "The notification will be dismissed when opening the room.")
    }
    
    func testDeclineInvite() async throws {
        setupViewModel(invites: .rooms)
        let invitedRoomIDs = context.viewState.rooms.invites.compactMap(\.roomID)
        appSettings.seenInvites = Set(invitedRoomIDs)
        XCTAssertEqual(invitedRoomIDs.count, 2)
        
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.send(viewAction: .declineInvite(roomIdentifier: invitedRoomIDs[0]))
        try await deferred.fulfill()
        
        let rejectExpectation = expectation(description: "Expected rejectInvitation to be called.")
        clientProxy.roomForIdentifierClosure = { _ in
            let roomProxy = InvitedRoomProxyMock(.init())
            roomProxy.rejectInvitationClosure = {
                rejectExpectation.fulfill()
                return .success(())
            }
            
            return .invited(roomProxy)
        }
        context.viewState.bindings.alertInfo?.verticalButtons?[0].action?()
        await fulfillment(of: [rejectExpectation], timeout: 1.0)
        
        XCTAssertEqual(appSettings.seenInvites, [invitedRoomIDs[1]])
        XCTAssertTrue(notificationManager.removeDeliveredMessageNotificationsForCalled)
        XCTAssertEqual(notificationManager.removeDeliveredMessageNotificationsForReceivedInvocations, [invitedRoomIDs[0]])
    }
    
    func testDeclineAndBlockInvite() async throws {
        setupViewModel(invites: .rooms)
        let invitedRoomIDs = context.viewState.rooms.invites.compactMap(\.roomID)
        appSettings.seenInvites = Set(invitedRoomIDs)
        XCTAssertEqual(invitedRoomIDs.count, 2)
        
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.send(viewAction: .declineInvite(roomIdentifier: invitedRoomIDs[0]))
        try await deferred.fulfill()
        
        let deferredAction = deferFulfillment(viewModel.actions) { $0 == .presentDeclineAndBlock(userID: RoomMemberProxyMock.mockCharlie.userID, roomID: invitedRoomIDs[0]) }
        context.viewState.bindings.alertInfo?.secondaryButton?.action?()
        try await deferredAction.fulfill()
    }
    
    func testNewSoundBanner() {
        appSettings.hasSeenNewSoundBanner = false
        
        setupViewModel()
        XCTAssertTrue(context.viewState.shouldShowBanner)
        XCTAssertTrue(context.viewState.shouldShowNewSoundBanner)
        
        context.send(viewAction: .dismissNewSoundBanner)
        XCTAssertFalse(context.viewState.shouldShowBanner)
        XCTAssertFalse(context.viewState.shouldShowNewSoundBanner)
        XCTAssertTrue(appSettings.hasSeenNewSoundBanner)
    }
    
    // MARK: - Helpers
    
    enum InviteType { case rooms, spaces }
    
    private func setupViewModel(securityStatePublisher: CurrentValuePublisher<SessionSecurityState, Never>? = nil, invites: InviteType? = nil) {
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
                .success(SpaceRoomListProxyMock(.init(spaceServiceRoom: SpaceServiceRoomMock(.init(id: spaceID, isSpace: true)))))
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
