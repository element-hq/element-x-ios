//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class KnockRequestsListScreenViewModelTests: XCTestCase {
    var viewModel: KnockRequestsListScreenViewModelProtocol!
    
    var context: KnockRequestsListScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUpWithError() throws {
        AppSettings.resetAllSettings()
    }
    
    func testLoadingState() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init(knockRequestsState: .loading, joinRule: .knock))
        viewModel = KnockRequestsListScreenViewModel(roomProxy: roomProxyMock,
                                                     mediaProvider: MediaProviderMock(),
                                                     userIndicatorController: UserIndicatorControllerMock())
        
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
    
    func testEmptyState() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init(knockRequestsState: .loaded([]), joinRule: .knock))
        viewModel = KnockRequestsListScreenViewModel(roomProxy: roomProxyMock,
                                                     mediaProvider: MediaProviderMock(),
                                                     userIndicatorController: UserIndicatorControllerMock())
        
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
    
    func testLoadedState() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init(members: [.mockAdmin],
                                                      knockRequestsState: .loaded([KnockRequestProxyMock(.init(eventID: "1", userID: "@alice:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "2", userID: "@bob:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "3", userID: "@charlie:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "4", userID: "@dan:matrix.org"))]),
                                                      ownUserID: RoomMemberProxyMock.mockAdmin.userID,
                                                      joinRule: .knock))
        viewModel = KnockRequestsListScreenViewModel(roomProxy: roomProxyMock,
                                                     mediaProvider: MediaProviderMock(),
                                                     userIndicatorController: UserIndicatorControllerMock())
        
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
            XCTFail("Can't be nil")
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
            XCTFail("Can't be nil")
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
    
    func testAcceptAll() async throws {
        let roomProxyMock = JoinedRoomProxyMock(.init(knockRequestsState: .loaded([KnockRequestProxyMock(.init(eventID: "1", userID: "@alice:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "2", userID: "@bob:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "3", userID: "@charlie:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "4", userID: "@dan:matrix.org"))]),
                                                      joinRule: .knock))
        viewModel = KnockRequestsListScreenViewModel(roomProxy: roomProxyMock,
                                                     mediaProvider: MediaProviderMock(),
                                                     userIndicatorController: UserIndicatorControllerMock())
        
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
            XCTFail("Can't be nil")
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
    
    func testLoadedStateBecomesEmptyIfTheJoinRuleIsNotKnocking() async throws {
        // If there is a sudden change in the rule, but the requests are still published, we want to hide all of them and show the empty view
        let roomProxyMock = JoinedRoomProxyMock(.init(members: [.mockAdmin],
                                                      knockRequestsState: .loaded([KnockRequestProxyMock(.init(eventID: "1", userID: "@alice:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "2", userID: "@bob:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "3", userID: "@charlie:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "4", userID: "@dan:matrix.org"))]),
                                                      ownUserID: RoomMemberProxyMock.mockAdmin.userID,
                                                      joinRule: .invite))
        viewModel = KnockRequestsListScreenViewModel(roomProxy: roomProxyMock,
                                                     mediaProvider: MediaProviderMock(),
                                                     userIndicatorController: UserIndicatorControllerMock())
        
        let deferred = deferFulfillment(context.$viewState) { state in
            !state.shouldDisplayRequests &&
                state.shouldDisplayEmptyView &&
                !state.isLoading &&
                !state.isKnockableRoom
        }
        try await deferred.fulfill()
    }
    
    func testLoadedStateBecomesEmptyIfPermissionsAreRemoved() async throws {
        // If there is a sudden change in permissions, and the user can't do any other action, we hide all the requests and shoe the empty view
        let roomProxyMock = JoinedRoomProxyMock(.init(knockRequestsState: .loaded([KnockRequestProxyMock(.init(eventID: "1", userID: "@alice:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "2", userID: "@bob:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "3", userID: "@charlie:matrix.org")),
                                                                                   KnockRequestProxyMock(.init(eventID: "4", userID: "@dan:matrix.org"))]),
                                                      canUserInvite: false,
                                                      joinRule: .knock))
        viewModel = KnockRequestsListScreenViewModel(roomProxy: roomProxyMock,
                                                     mediaProvider: MediaProviderMock(),
                                                     userIndicatorController: UserIndicatorControllerMock())
        
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
