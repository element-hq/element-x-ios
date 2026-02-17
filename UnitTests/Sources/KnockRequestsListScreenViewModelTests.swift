//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@MainActor
@Suite(.serialized)
struct KnockRequestsListScreenViewModelTests {
    init() {
        AppSettings.resetAllSettings()
    }
    
    @Test
    func loadingState() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init(knockRequestsState: .loading, joinRule: .knock))
        let viewModel = KnockRequestsListScreenViewModel(roomProxy: roomProxyMock,
                                                         mediaProvider: MediaProviderMock(),
                                                         userIndicatorController: UserIndicatorControllerMock())
        let context = viewModel.context
        
        let deferred = deferFulfillment(context.$viewState) { state in
            !state.shouldDisplayRequests &&
                state.isKnockableRoom &&
                state.canAccept &&
                !state.canBan &&
                !state.canDecline &&
                state.isLoading &&
                !state.shouldDisplayEmptyView
        }
        try await deferred.fulfill()
    }
    
    @Test
    func emptyState() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init(knockRequestsState: .loaded([]), joinRule: .knock))
        let viewModel = KnockRequestsListScreenViewModel(roomProxy: roomProxyMock,
                                                         mediaProvider: MediaProviderMock(),
                                                         userIndicatorController: UserIndicatorControllerMock())
        let context = viewModel.context
        
        let deferred = deferFulfillment(context.$viewState) { state in
            !state.shouldDisplayRequests &&
                state.isKnockableRoom &&
                state.canAccept &&
                !state.canBan &&
                !state.canDecline &&
                !state.isLoading &&
                state.shouldDisplayEmptyView
        }
        try await deferred.fulfill()
    }
    
    @Test
    func loadedState() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init(members: [.mockAdmin],
                                                      knockRequestsState: .loaded([KnockRequestProxyMock(.init(eventID: "1", userID: "@alice:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "2", userID: "@bob:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "3", userID: "@charlie:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "4", userID: "@dan:matrix.org"))]),
                                                      ownUserID: RoomMemberProxyMock.mockAdmin.userID,
                                                      joinRule: .knock))
        let viewModel = KnockRequestsListScreenViewModel(roomProxy: roomProxyMock,
                                                         mediaProvider: MediaProviderMock(),
                                                         userIndicatorController: UserIndicatorControllerMock())
        let context = viewModel.context
        
        var deferred = deferFulfillment(context.$viewState) { state in
            state.shouldDisplayRequests &&
                state.isKnockableRoom &&
                state.canAccept &&
                state.canBan &&
                state.canDecline &&
                !state.isLoading &&
                !state.shouldDisplayEmptyView &&
                state.displayedRequests.count == 4 &&
                state.handledEventIDs.isEmpty &&
                state.shouldDisplayAcceptAllButton
        }
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.$viewState) { state in
            state.shouldDisplayRequests &&
                state.handledEventIDs == ["1"] &&
                !state.shouldDisplayEmptyView &&
                state.displayedRequests.count == 3 &&
                state.shouldDisplayAcceptAllButton
        }
        context.send(viewAction: .acceptRequest(eventID: "1"))
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.alertInfo?.id == .declineRequest
        }
        context.send(viewAction: .declineRequest(eventID: "2"))
        try await deferred.fulfill()
        
        guard let declineAlertInfo = context.alertInfo else {
            Issue.record("Can't be nil")
            return
        }
        deferred = deferFulfillment(context.$viewState) { state in
            state.shouldDisplayRequests &&
                state.handledEventIDs == ["1", "2"] &&
                !state.shouldDisplayEmptyView &&
                state.displayedRequests.count == 2 &&
                state.shouldDisplayAcceptAllButton
        }
        declineAlertInfo.primaryButton.action?()
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.alertInfo?.id == .declineAndBan
        }
        context.send(viewAction: .ban(eventID: "3"))
        try await deferred.fulfill()
        
        guard let banAlertInfo = context.alertInfo else {
            Issue.record("Can't be nil")
            return
        }
        deferred = deferFulfillment(context.$viewState) { state in
            state.shouldDisplayRequests &&
                state.handledEventIDs == ["1", "2", "3"] &&
                !state.shouldDisplayEmptyView &&
                state.displayedRequests.count == 1 &&
                !state.shouldDisplayAcceptAllButton
        }
        banAlertInfo.primaryButton.action?()
        try await deferred.fulfill()
    }
    
    @Test
    func acceptAll() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init(knockRequestsState: .loaded([KnockRequestProxyMock(.init(eventID: "1", userID: "@alice:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "2", userID: "@bob:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "3", userID: "@charlie:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "4", userID: "@dan:matrix.org"))]),
                                                      joinRule: .knock))
        let viewModel = KnockRequestsListScreenViewModel(roomProxy: roomProxyMock,
                                                         mediaProvider: MediaProviderMock(),
                                                         userIndicatorController: UserIndicatorControllerMock())
        let context = viewModel.context
        
        var deferred = deferFulfillment(context.$viewState) { state in
            state.shouldDisplayRequests &&
                state.isKnockableRoom &&
                state.canAccept &&
                !state.canBan &&
                !state.canDecline &&
                !state.isLoading &&
                !state.shouldDisplayEmptyView &&
                state.displayedRequests.count == 4 &&
                state.handledEventIDs.isEmpty &&
                state.shouldDisplayAcceptAllButton
        }
        try await deferred.fulfill()
        
        deferred = deferFulfillment(context.$viewState) { state in
            state.bindings.alertInfo?.id == .acceptAllRequests
        }
        context.send(viewAction: .acceptAllRequests)
        try await deferred.fulfill()
        
        guard let alertInfo = context.alertInfo else {
            Issue.record("Can't be nil")
            return
        }
        
        deferred = deferFulfillment(context.$viewState) { state in
            !state.shouldDisplayRequests &&
                state.handledEventIDs == ["1", "2", "3", "4"] &&
                !state.isLoading &&
                state.shouldDisplayEmptyView
        }
        alertInfo.primaryButton.action?()
        try await deferred.fulfill()
    }
    
    @Test
    func loadedStateBecomesEmptyIfTheJoinRuleIsNotKnocking() async throws {
        // If there is a sudden change in the rule, but the requests are still published, we want to hide all of them and show the empty view
        let roomProxyMock = JoinedRoomProxyMock(.init(members: [.mockAdmin],
                                                      knockRequestsState: .loaded([KnockRequestProxyMock(.init(eventID: "1", userID: "@alice:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "2", userID: "@bob:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "3", userID: "@charlie:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "4", userID: "@dan:matrix.org"))]),
                                                      ownUserID: RoomMemberProxyMock.mockAdmin.userID,
                                                      joinRule: .invite))
        let viewModel = KnockRequestsListScreenViewModel(roomProxy: roomProxyMock,
                                                         mediaProvider: MediaProviderMock(),
                                                         userIndicatorController: UserIndicatorControllerMock())
        let context = viewModel.context
        
        let deferred = deferFulfillment(context.$viewState) { state in
            !state.shouldDisplayRequests &&
                state.shouldDisplayEmptyView &&
                !state.isLoading &&
                !state.isKnockableRoom
        }
        try await deferred.fulfill()
    }
    
    @Test
    func loadedStateBecomesEmptyIfPermissionsAreRemoved() async throws {
        // If there is a sudden change in permissions, and the user can't do any other action, we hide all the requests and shoe the empty view
        let roomProxyMock = JoinedRoomProxyMock(.init(knockRequestsState: .loaded([KnockRequestProxyMock(.init(eventID: "1", userID: "@alice:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "2", userID: "@bob:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "3", userID: "@charlie:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "4", userID: "@dan:matrix.org"))]),
                                                      joinRule: .knock,
                                                      powerLevelsConfiguration: .init(canUserInvite: false)))
        let viewModel = KnockRequestsListScreenViewModel(roomProxy: roomProxyMock,
                                                         mediaProvider: MediaProviderMock(),
                                                         userIndicatorController: UserIndicatorControllerMock())
        let context = viewModel.context
        
        let deferred = deferFulfillment(context.$viewState) { state in
            !state.shouldDisplayRequests &&
                state.shouldDisplayEmptyView &&
                !state.canAccept &&
                !state.canBan &&
                !state.canDecline &&
                !state.isLoading
        }
        try await deferred.fulfill()
    }
}
