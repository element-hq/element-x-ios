//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import XCTest

@MainActor
class ReportRoomScreenViewModelTests: XCTestCase {
    var viewModel: ReportRoomScreenViewModelProtocol!
    var roomProxy: JoinedRoomProxyMock!
    
    var context: ReportRoomScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUp() {
        roomProxy = JoinedRoomProxyMock(.init())
        viewModel = ReportRoomScreenViewModel(roomProxy: roomProxy, userIndicatorController: UserIndicatorControllerMock())
    }
    
    func testInitialState() {
        XCTAssertTrue(context.viewState.bindings.reason.isEmpty)
        XCTAssertFalse(context.viewState.bindings.shouldLeaveRoom)
    }
    
    func testReportSuccess() async throws {
        let reason = "Spam"
        let expectation = XCTestExpectation(description: "Report success")
        roomProxy.reportRoomReasonClosure = { reasonArgument in
            defer { expectation.fulfill() }
            XCTAssertEqual(reasonArgument, reason)
            return .success(())
        }
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            action == .dismiss(shouldLeaveRoom: false)
        }
        
        context.reason = reason
        context.send(viewAction: .report)
        
        try await deferred.fulfill()
        await fulfillment(of: [expectation])
    }
    
    func testReportAndLeaveSuccess() async throws {
        let reason = "Spam"
        let reportExpectation = XCTestExpectation(description: "Report success")
        roomProxy.reportRoomReasonClosure = { reasonArgument in
            defer { reportExpectation.fulfill() }
            XCTAssertEqual(reasonArgument, reason)
            return .success(())
        }
        
        let leaveExpectation = XCTestExpectation(description: "Leave success")
        roomProxy.leaveRoomClosure = {
            defer { leaveExpectation.fulfill() }
            return .success(())
        }
        
        let deferred = deferFulfillment(viewModel.actionsPublisher) { action in
            action == .dismiss(shouldLeaveRoom: true)
        }
        
        context.reason = reason
        context.shouldLeaveRoom = true
        context.send(viewAction: .report)
        
        await fulfillment(of: [reportExpectation, leaveExpectation])
        try await deferred.fulfill()
    }
    
    func testReportSuccessLeaveFails() async throws {
        let reason = "Spam"
        let reportExpectation = XCTestExpectation(description: "Report success")
        roomProxy.reportRoomReasonClosure = { reasonArgument in
            defer { reportExpectation.fulfill() }
            XCTAssertEqual(reasonArgument, reason)
            return .success(())
        }
        
        let leaveExpectation = XCTestExpectation(description: "Leave fails")
        roomProxy.leaveRoomClosure = {
            defer { leaveExpectation.fulfill() }
            return .failure(.eventNotFound)
        }
        
        let deferred = deferFulfillment(context.observe(\.viewState.bindings.alert)) { $0 != nil }
        
        context.reason = reason
        context.shouldLeaveRoom = true
        context.send(viewAction: .report)
        
        await fulfillment(of: [reportExpectation, leaveExpectation])
        try await deferred.fulfill()
    }
}
