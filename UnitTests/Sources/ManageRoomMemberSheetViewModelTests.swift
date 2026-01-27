//
// Copyright 2025 Element Creations Ltd.
// Copyright 2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class ManageRoomMemberSheetViewModelTests: XCTestCase {
    private var viewModel: ManageRoomMemberSheetViewModel!
    private var context: ManageRoomMemberSheetViewModel.Context! {
        viewModel.context
    }
    
    func testKick() async throws {
        let testReason = "Kick Test"
        let roomProxy = JoinedRoomProxyMock(.init(members: [RoomMemberProxyMock.mockAdmin, RoomMemberProxyMock.mockAlice]))
        let expectation = XCTestExpectation(description: "Kick member")
        roomProxy.kickUserReasonClosure = { userID, reason in
            defer { expectation.fulfill() }
            XCTAssertEqual(userID, RoomMemberProxyMock.mockAlice.userID)
            XCTAssertEqual(reason, testReason)
            return .success(())
        }
        
        viewModel = ManageRoomMemberSheetViewModel(memberDetails: .memberDetails(roomMember: .init(withProxy: RoomMemberProxyMock.mockAlice)),
                                                   permissions: .init(canKick: true, canBan: true, ownPowerLevel: RoomMemberProxyMock.mockAdmin.powerLevel),
                                                   roomProxy: roomProxy,
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   analyticsService: ServiceLocator.shared.analytics,
                                                   mediaProvider: MediaProviderMock(configuration: .init()))
        
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) { $0 != nil }
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            action == .dismiss(shouldShowDetails: false)
        }
        context.send(viewAction: .kick)
        try await deferred.fulfill()
        
        context.alertInfo?.textFields?[0].text.wrappedValue = testReason
        context.alertInfo?.secondaryButton?.action?()
        await fulfillment(of: [expectation])
        try await deferredAction.fulfill()
    }
    
    func testBan() async throws {
        let testReason = "Ban Test"
        let roomProxy = JoinedRoomProxyMock(.init(members: [RoomMemberProxyMock.mockAdmin, RoomMemberProxyMock.mockAlice]))
        let expectation = XCTestExpectation(description: "Ban member")
        roomProxy.banUserReasonClosure = { userID, reason in
            defer { expectation.fulfill() }
            XCTAssertEqual(userID, RoomMemberProxyMock.mockAlice.userID)
            XCTAssertEqual(reason, testReason)
            return .success(())
        }
        
        viewModel = ManageRoomMemberSheetViewModel(memberDetails: .memberDetails(roomMember: .init(withProxy: RoomMemberProxyMock.mockAlice)),
                                                   permissions: .init(canKick: true, canBan: true, ownPowerLevel: RoomMemberProxyMock.mockAdmin.powerLevel),
                                                   roomProxy: roomProxy,
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   analyticsService: ServiceLocator.shared.analytics,
                                                   mediaProvider: MediaProviderMock(configuration: .init()))
        
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.alertInfo)) { $0 != nil }
        context.send(viewAction: .ban)
        try await deferred.fulfill()
        
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            action == .dismiss(shouldShowDetails: false)
        }
        context.alertInfo?.textFields?[0].text.wrappedValue = testReason
        context.alertInfo?.secondaryButton?.action?()
        await fulfillment(of: [expectation])
        try await deferredAction.fulfill()
    }
    
    func testDisplayDetails() async throws {
        let roomProxy = JoinedRoomProxyMock(.init(members: [RoomMemberProxyMock.mockAdmin, RoomMemberProxyMock.mockAlice]))
        viewModel = ManageRoomMemberSheetViewModel(memberDetails: .memberDetails(roomMember: .init(withProxy: RoomMemberProxyMock.mockAlice)),
                                                   permissions: .init(canKick: true, canBan: true, ownPowerLevel: RoomMemberProxyMock.mockAdmin.powerLevel),
                                                   roomProxy: roomProxy,
                                                   userIndicatorController: UserIndicatorControllerMock(),
                                                   analyticsService: ServiceLocator.shared.analytics,
                                                   mediaProvider: MediaProviderMock(configuration: .init()))
        
        let deferredAction = deferFulfillment(viewModel.actions) { action in
            action == .dismiss(shouldShowDetails: true)
        }
        context.send(viewAction: .displayDetails)
        try await deferredAction.fulfill()
        XCTAssertNil(context.alertInfo)
    }
}
