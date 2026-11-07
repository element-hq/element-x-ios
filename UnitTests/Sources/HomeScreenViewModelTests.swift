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
final class HomeScreenViewModelTests {
    var viewModel: HomeScreenViewModelProtocol!
    var context: HomeScreenViewModelType.Context! {
        viewModel.context
    }
    
    var clientProxy: ClientProxyMock!
    var roomSummaryProvider: RoomSummaryProviderMock!
    var notificationService: NotificationServiceMock!
    private let userSettings: UserSettings
    
    var cancellables = Set<AnyCancellable>()
    
    init() {
        userSettings = UserSettings.mock()
    }
    
    @Test("Selecting a room asks to present it")
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
    
    @Test("Tapping the user avatar asks to show the settings")
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
    
    @Test("Leaving a room shows its confirmation alert")
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
    
    @Test("Failing to leave a room shows an error alert")
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
    
    @Test("Leaving a room reports that it was left")
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
    
    @Test("Showing room details asks to present them")
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
    
    @Test("Activating a filter narrows down the room list")
    func filters() async throws {
        setupViewModel()
        
        context.filtersState.activateFilter(.people)
        try await Task.sleep(for: .milliseconds(100))
        #expect(roomSummaryProvider.roomListPublisher.value.count == 2)
        #expect(roomSummaryProvider.roomListPublisher.value.first?.name == "Foundation and Earth")
    }
    
    @Test("Searching narrows down the room list")
    func search() async throws {
        setupViewModel()
        
        context.isSearchFieldFocused = true
        context.searchQuery = "lude to Found"
        try await Task.sleep(for: .milliseconds(100))
        #expect(roomSummaryProvider.roomListPublisher.value.first?.name == "Prelude to Foundation")
        #expect(roomSummaryProvider.roomListPublisher.value.count == 1)
    }
    
    @Test("The empty filter state is hidden while searching")
    func filtersEmptyState() async throws {
        setupViewModel()
        
        context.filtersState.activateFilter(.people)
        context.filtersState.activateFilter(.favourites)
        try await Task.sleep(for: .milliseconds(100))
        #expect(context.viewState.shouldShowEmptyFilterState)
        context.isSearchFieldFocused = true
        #expect(!context.viewState.shouldShowEmptyFilterState)
    }
    
    @Test("The set up recovery banner shows while recovery is disabled")
    func setUpRecoveryBannerState() async throws {
        // Given a view model without a visible security banner.
        let securityStateStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .verified, recoveryState: .unknown))
        setupViewModel(securityStatePublisher: securityStateStateSubject.asCurrentValuePublisher())
        #expect(context.viewState.securityBannerMode == .none)
        
        // When the recovery state comes through as disabled.
        var deferred = deferFulfillment(context.$viewState) { $0.securityBannerMode == .show(.setUpRecovery) }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .disabled))
        
        // Then the banner should be shown to set up recovery.
        try await deferred.fulfill()
        
        // When the recovery is enabled.
        deferred = deferFulfillment(context.$viewState) { $0.securityBannerMode == .none }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .enabled))
        
        // Then the banner should no longer be shown.
        try await deferred.fulfill()
    }
    
    @Test("A dismissed set up recovery banner stays dismissed")
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
        let failure = deferFailure(context.$viewState, timeout: .milliseconds(300)) { $0.securityBannerMode != .dismissed }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .disabled))
        try await failure.fulfill()
    }
    
    @Test("The out of sync banner shows while recovery is incomplete")
    func outOfSyncRecoveryBannerState() async throws {
        // Given a view model without a visible security banner.
        let securityStateStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .verified, recoveryState: .unknown))
        setupViewModel(securityStatePublisher: securityStateStateSubject.asCurrentValuePublisher())
        #expect(context.viewState.securityBannerMode == .none)
        
        // When the recovery state comes through as incomplete.
        var deferred = deferFulfillment(context.$viewState) { $0.securityBannerMode == .show(.recoveryOutOfSync) }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .incomplete))
        
        // Then the banner should be shown for out of sync recovery.
        try await deferred.fulfill()
        
        // When the recovery is enabled.
        deferred = deferFulfillment(context.$viewState) { $0.securityBannerMode == .none }
        securityStateStateSubject.send(.init(verificationState: .verified, recoveryState: .enabled))
        
        // Then the banner should no longer be shown.
        try await deferred.fulfill()
    }
    
    @Test("The set up recovery banner starts creating the recovery key")
    func setUpRecoveryBannerStartsTheRecoveryKeyFlow() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .presentRecoveryKeyScreen }
        context.send(viewAction: .setupRecovery)
        try await deferred.fulfill()
    }
    
    @Test("The out of sync banner asks for the recovery key")
    func outOfSyncRecoveryBannerStartsTheRecoveryKeyFlow() async throws {
        setupViewModel()
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .presentRecoveryKeyScreen }
        context.send(viewAction: .confirmRecoveryKey)
        try await deferred.fulfill()
    }
    
    @Test("Invites lose their unread badge once they have been seen")
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
        userSettings.account.seenInvites = Set(invites.compactMap(\.roomID))
        try await deferred.fulfill()
        invites = context.viewState.rooms.invites
        
        for invite in invites {
            #expect(!invite.badges.isDotShown)
        }
    }
    
    @Test("Accepting an invite presents the room and marks the invite as seen")
    func acceptInvite() async throws {
        setupViewModel(invites: .rooms)
        
        let invitedRoomIDs = context.viewState.rooms.invites.compactMap(\.roomID)
        userSettings.account.seenInvites = Set(invitedRoomIDs)
        #expect(invitedRoomIDs.count == 2)
        
        let deferred = deferFulfillment(viewModel.actions) { $0 == .presentRoom(roomIdentifier: invitedRoomIDs[0]) }
        context.send(viewAction: .acceptInvite(roomIdentifier: invitedRoomIDs[0]))
        try await deferred.fulfill()
        
        #expect(userSettings.account.seenInvites == [invitedRoomIDs[1]])
        #expect(!notificationService.removeDeliveredMessageNotificationsForCalled, "The notification will be dismissed when opening the room.")
    }
    
    @Test("Accepting a space invite presents the space and marks the invite as seen")
    func acceptSpaceInvite() async throws {
        setupViewModel(invites: .spaces)
        
        let invitedRoomIDs = context.viewState.rooms.invites.compactMap(\.roomID)
        userSettings.account.seenInvites = Set(invitedRoomIDs)
        #expect(invitedRoomIDs.count == 2)
        
        let deferred = deferFulfillment(viewModel.actions) {
            $0 == .presentSpace(SpaceRoomListProxyMock(.init(spaceServiceRoom: SpaceServiceRoom.mock(id: invitedRoomIDs[0], isSpace: true))))
        }
        context.send(viewAction: .acceptInvite(roomIdentifier: invitedRoomIDs[0]))
        try await deferred.fulfill()
        
        #expect(userSettings.account.seenInvites == [invitedRoomIDs[1]])
        #expect(!notificationService.removeDeliveredMessageNotificationsForCalled, "The notification will be dismissed when opening the room.")
    }
    
    @Test("Declining an invite asks for confirmation")
    func declineInvite() async throws {
        setupViewModel(invites: .rooms)
        let invitedRoomIDs = context.viewState.rooms.invites.compactMap(\.roomID)
        userSettings.account.seenInvites = Set(invitedRoomIDs)
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
        
        #expect(userSettings.account.seenInvites == [invitedRoomIDs[1]])
        #expect(notificationService.removeDeliveredMessageNotificationsForCalled)
        #expect(notificationService.removeDeliveredMessageNotificationsForReceivedInvocations == [invitedRoomIDs[0]])
    }
    
    @Test("Declining and blocking an invite asks to block the inviter")
    func declineAndBlockInvite() async throws {
        setupViewModel(invites: .rooms)
        let invitedRoomIDs = context.viewState.rooms.invites.compactMap(\.roomID)
        userSettings.account.seenInvites = Set(invitedRoomIDs)
        #expect(invitedRoomIDs.count == 2)
        
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.alertInfo != nil }
        context.send(viewAction: .declineInvite(roomIdentifier: invitedRoomIDs[0]))
        try await deferred.fulfill()
        
        let deferredAction = deferFulfillment(viewModel.actions) { $0 == .presentDeclineAndBlock(userID: RoomMemberProxyMock.mockCharlie.userID, roomID: invitedRoomIDs[0]) }
        context.viewState.bindings.alertInfo?.secondaryButton?.action?()
        try await deferredAction.fulfill()
    }
    
    @Test("The new sound banner can be dismissed")
    func newSoundBanner() {
        userSettings.app.hasSeenNewSoundBanner = false
        
        setupViewModel()
        #expect(context.viewState.shouldShowBanner)
        #expect(context.viewState.shouldShowNewSoundBanner)
        
        context.send(viewAction: .dismissNewSoundBanner)
        #expect(!context.viewState.shouldShowBanner)
        #expect(!context.viewState.shouldShowNewSoundBanner)
        #expect(userSettings.app.hasSeenNewSoundBanner)
    }
    
    @Test("The multi-account announcement is presented when the screen appears")
    func multiAccountAnnouncement() async throws {
        userSettings.app.multiAccountEnabled = true
        setupViewModel()
        
        // Arming it after the view model exists (Developer options) doesn't present it on its own.
        userSettings.app.hasSeenMultiAccountAnnouncement = false
        let deferredFailure = deferFailure(context.$viewState, timeout: .milliseconds(300)) { $0.bindings.isPresentingMultiAccountAnnouncement }
        try await deferredFailure.fulfill()
        
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.isPresentingMultiAccountAnnouncement }
        context.send(viewAction: .screenAppeared)
        try await deferred.fulfill()
        #expect(!userSettings.app.hasSeenMultiAccountAnnouncement)
        
        context.send(viewAction: .multiAccountAnnouncementAppeared)
        #expect(userSettings.app.hasSeenMultiAccountAnnouncement)
        #expect(context.viewState.bindings.isPresentingMultiAccountAnnouncement)
        
        // A swipe down dismisses it without any of the announcement's actions.
        context.isPresentingMultiAccountAnnouncement = false
        let deferredReappearance = deferFailure(context.$viewState, timeout: .milliseconds(300)) { $0.bindings.isPresentingMultiAccountAnnouncement }
        context.send(viewAction: .screenAppeared)
        try await deferredReappearance.fulfill()
    }
    
    @Test("The multi-account announcement's actions dismiss it", arguments: [HomeScreenViewAction.dismissMultiAccountAnnouncement, .addAccount])
    func multiAccountAnnouncementActionsDismissIt(_ action: HomeScreenViewAction) async throws {
        userSettings.app.multiAccountEnabled = true
        userSettings.app.hasSeenMultiAccountAnnouncement = false
        setupViewModel()
        
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.isPresentingMultiAccountAnnouncement }
        context.send(viewAction: .screenAppeared)
        try await deferred.fulfill()
        
        context.send(viewAction: action)
        #expect(!context.viewState.bindings.isPresentingMultiAccountAnnouncement)
    }
    
    @Test("The multi-account announcement stays hidden when it doesn't apply", arguments: MultiAccountAnnouncementHiddenCase.allCases)
    func multiAccountAnnouncementHidden(_ hiddenCase: MultiAccountAnnouncementHiddenCase) async throws {
        userSettings.app.multiAccountEnabled = hiddenCase != .flagOff
        userSettings.app.hasSeenMultiAccountAnnouncement = hiddenCase == .alreadySeen
        let verificationState: SessionVerificationState = switch hiddenCase {
        case .unverified: .unverified
        case .unknownVerificationState: .unknown
        case .flagOff, .alreadySeen: .verified
        }
        let securityStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: verificationState, recoveryState: .enabled))
        setupViewModel(securityStatePublisher: securityStateSubject.asCurrentValuePublisher())
        
        let deferred = deferFailure(context.$viewState, timeout: .milliseconds(300)) { $0.bindings.isPresentingMultiAccountAnnouncement }
        context.send(viewAction: .screenAppeared)
        try await deferred.fulfill()
        #expect(userSettings.app.hasSeenMultiAccountAnnouncement == (hiddenCase == .alreadySeen))
    }
    
    @Test("The multi-account announcement waits for the next appearance once verified")
    func multiAccountAnnouncementPresentsOnTheNextAppearanceOnceVerified() async throws {
        userSettings.app.multiAccountEnabled = true
        userSettings.app.hasSeenMultiAccountAnnouncement = false
        let securityStateSubject = CurrentValueSubject<SessionSecurityState, Never>(.init(verificationState: .unverified, recoveryState: .enabled))
        setupViewModel(securityStatePublisher: securityStateSubject.asCurrentValuePublisher())
        
        let deferredFailure = deferFailure(context.$viewState, timeout: .milliseconds(300)) { $0.bindings.isPresentingMultiAccountAnnouncement }
        context.send(viewAction: .screenAppeared)
        try await deferredFailure.fulfill()
        
        // Becoming verified doesn't present it on its own…
        securityStateSubject.send(.init(verificationState: .verified, recoveryState: .enabled))
        let deferredVerifiedFailure = deferFailure(context.$viewState, timeout: .milliseconds(300)) { $0.bindings.isPresentingMultiAccountAnnouncement }
        try await deferredVerifiedFailure.fulfill()
        
        // …the room list appearing again does, e.g. once the identity confirmation cover is dismissed.
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.isPresentingMultiAccountAnnouncement }
        context.send(viewAction: .screenAppeared)
        try await deferred.fulfill()
    }
    
    @Test("The multi-account announcement is marked as seen when there are several accounts")
    func multiAccountAnnouncementIsMarkedSeenWithSeveralAccounts() async throws {
        userSettings.app.multiAccountEnabled = true
        userSettings.app.hasSeenMultiAccountAnnouncement = false
        setupViewModel(otherAccountUserIDs: ["@other:client.com"])
        
        let deferred = deferFailure(context.$viewState, timeout: .milliseconds(300)) { $0.bindings.isPresentingMultiAccountAnnouncement }
        context.send(viewAction: .screenAppeared)
        try await deferred.fulfill()
        
        #expect(userSettings.app.hasSeenMultiAccountAnnouncement)
    }
    
    // MARK: - Helpers
    
    enum InviteType { case rooms, spaces }
    
    enum MultiAccountAnnouncementHiddenCase: CaseIterable { case flagOff, alreadySeen, unverified, unknownVerificationState }
    
    @Test("The room list mode is available straight away on a warm launch")
    func roomListModeIsSetSynchronouslyOnAWarmLaunch() {
        setupViewModel()
        
        // No awaiting, the mode must not need the subscription's async delivery.
        #expect(context.viewState.roomListMode == .rooms)
    }
    
    @Test("The room list waits for the rooms to be published before leaving the skeletons")
    func roomListModeWaitsForTheRoomsToPublish() async throws {
        let (roomListSubject, stateSubject) = setupViewModelWithManualProvider()
        
        #expect(context.viewState.roomListMode == .skeletons)
        
        // The provider reports loaded before the first summaries have been published.
        let failure = deferFailure(context.$viewState, timeout: .milliseconds(300)) { $0.roomListMode != .skeletons }
        stateSubject.send(.loaded(totalNumberOfRooms: 8))
        try await failure.fulfill()
        
        let deferred = deferFulfillment(context.$viewState) { $0.roomListMode == .rooms }
        roomListSubject.send(.mockRooms)
        try await deferred.fulfill()
    }
    
    @Test("An empty filtered result doesn't keep the skeletons showing")
    func roomListModeDoesntHoldSkeletonsForAnEmptyFilteredResult() async throws {
        let (roomListSubject, stateSubject) = setupViewModelWithManualProvider()
        #expect(context.viewState.roomListMode == .skeletons)
        
        // A filter is active before anything has published and the filtered list is loaded but empty.
        context.filtersState.activateFilter(.people)
        let deferred = deferFulfillment(context.$viewState) { $0.roomListMode == .rooms }
        roomListSubject.send([])
        stateSubject.send(.loaded(totalNumberOfRooms: 8))
        try await deferred.fulfill()
    }
    
    @Test("The room list goes straight to the rooms once the cached ones are published")
    func roomListModeGoesStraightToTheCachedRooms() async throws {
        let (roomListSubject, _) = setupViewModelWithManualProvider(state: .loaded(totalNumberOfRooms: 8))
        #expect(context.viewState.roomListMode == .awaitingCachedRooms)
        
        let deferred = deferFulfillment(context.$viewState) { $0.roomListMode == .rooms }
        roomListSubject.send(.mockRooms)
        try await deferred.fulfill()
    }
    
    @Test("Skeletons show when the cached rooms are slow to arrive")
    func roomListModeShowsSkeletonsWhenTheCachedRoomsAreSlow() async throws {
        _ = setupViewModelWithManualProvider(state: .loaded(totalNumberOfRooms: 8))
        #expect(context.viewState.roomListMode == .awaitingCachedRooms)
        
        let deferred = deferFulfillment(context.$viewState) { $0.roomListMode == .skeletons }
        try await deferred.fulfill()
    }
    
    @Test("Filtering all the rooms out doesn't bring the skeletons back")
    func roomListModeDoesntReturnToSkeletonsWhenTheRoomsAreFilteredOut() async throws {
        let (roomListSubject, stateSubject) = setupViewModelWithManualProvider()
        
        stateSubject.send(.loaded(totalNumberOfRooms: 8))
        let deferred = deferFulfillment(context.$viewState) { $0.roomListMode == .rooms }
        roomListSubject.send(.mockRooms)
        try await deferred.fulfill()
        
        // A filter or a search without matches empties the list, the mode must not regress.
        let failure = deferFailure(context.$viewState, timeout: .milliseconds(300)) { $0.roomListMode != .rooms }
        roomListSubject.send([])
        stateSubject.send(.loaded(totalNumberOfRooms: 9))
        try await failure.fulfill()
    }
    
    private func setupViewModelWithManualProvider(state: RoomSummaryProviderState = .notLoaded) -> (CurrentValueSubject<[RoomSummary], Never>, CurrentValueSubject<RoomSummaryProviderState, Never>) {
        let roomListSubject = CurrentValueSubject<[RoomSummary], Never>([])
        let stateSubject = CurrentValueSubject<RoomSummaryProviderState, Never>(state)
        
        let provider = RoomSummaryProviderMock()
        provider.roomListPublisher = roomListSubject.asCurrentValuePublisher()
        provider.statePublisher = stateSubject.asCurrentValuePublisher()
        
        setupViewModel(roomSummaryProvider: provider)
        
        return (roomListSubject, stateSubject)
    }
    
    private func setupViewModel(otherAccountUserIDs: [String] = [], securityStatePublisher: CurrentValuePublisher<SessionSecurityState, Never>? = nil, invites: InviteType? = nil, roomSummaryProvider: RoomSummaryProviderMock? = nil) {
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
        
        self.roomSummaryProvider = roomSummaryProvider ?? RoomSummaryProviderMock(.init(state: .loaded(rooms)))
        
        clientProxy = ClientProxyMock(.init(userID: "@mock:client.com",
                                            roomSummaryProvider: self.roomSummaryProvider))
        
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
            clientProxy.spaceService = spaceServiceProxy
        case nil:
            break
        }
        
        notificationService = NotificationServiceMock(.init())
        let userSession = UserSessionMock(.init(clientProxy: clientProxy, userSettings: userSettings, notificationService: notificationService))
        if let securityStatePublisher {
            userSession.sessionSecurityStatePublisher = securityStatePublisher
        }
        
        let sessionDetails = [UserSessionDetails(userSession: userSession)] + otherAccountUserIDs.map { UserSessionDetails(userID: $0) }
        
        viewModel = HomeScreenViewModel(userSession: userSession,
                                        availableSessionsPublisher: .init(sessionDetails),
                                        selectedRoomPublisher: CurrentValueSubject<String?, Never>(nil).asCurrentValuePublisher(),
                                        analyticsService: AnalyticsServiceMock(.init()),
                                        bugReportService: BugReportServiceMock(.init()),
                                        userIndicatorController: UserIndicatorControllerMock())
    }
}

@MainActor
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

@MainActor
extension HomeScreenViewModelAction: @MainActor @retroactive Equatable {
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
        case (.logout, .logout):
            true
        default:
            false
        }
    }
}
