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
class DeclineAndBlockScreenViewModelTests: XCTestCase {
    var viewModel: DeclineAndBlockScreenViewModelProtocol!
    var clientProxy: ClientProxyMock!
    
    var context: DeclineAndBlockScreenViewModelType.Context {
        viewModel.context
    }
    
    override func setUp() {
        clientProxy = ClientProxyMock(.init())
        viewModel = DeclineAndBlockScreenViewModel(userID: "@alice:matrix.org",
                                                   roomID: "!room:matrix.org",
                                                   clientProxy: clientProxy,
                                                   userIndicatorController: UserIndicatorControllerMock())
    }
    
    func testInitialState() {
        XCTAssertFalse(context.viewState.isDeclineDisabled)
        XCTAssertFalse(context.shouldReport)
        XCTAssertTrue(context.shouldBlockUser)
    }
    
    func testDeclineDisabled() {
        context.shouldBlockUser = false
        XCTAssertTrue(context.viewState.isDeclineDisabled)
        XCTAssertFalse(context.shouldReport)
        XCTAssertFalse(context.shouldBlockUser)
        context.shouldReport = true
        // Should report set to `true` always requires a non empty reason
        XCTAssertTrue(context.viewState.isDeclineDisabled)
        context.reportReason = "Test reason"
        XCTAssertFalse(context.viewState.isDeclineDisabled)
    }
    
    func testDeclineBlockAndReport() async throws {
        let reason = "Test reason"
        clientProxy.roomForIdentifierClosure = { id in
            XCTAssertEqual(id, "!room:matrix.org")
            let roomProxyMock = InvitedRoomProxyMock(.init(id: id))
            roomProxyMock.rejectInvitationReturnValue = .success(())
            return .invited(InvitedRoomProxyMock(.init(id: id)))
        }
        clientProxy.reportRoomForIdentifierReasonClosure = { id, reasonValue in
            XCTAssertEqual(id, "!room:matrix.org")
            XCTAssertEqual(reasonValue, reason)
            return .success(())
        }
        clientProxy.ignoreUserClosure = { userId in
            XCTAssertEqual(userId, "@alice:matrix.org")
            return .success(())
        }
        
        context.shouldReport = true
        context.reportReason = reason
        
        let deferredAction = deferFulfillment(viewModel.actionsPublisher) { action in
            action == .dismiss(hasDeclined: true)
        }
        context.send(viewAction: .decline)
        try await deferredAction.fulfill()
        XCTAssertTrue(clientProxy.roomForIdentifierCalled)
        XCTAssertTrue(clientProxy.reportRoomForIdentifierReasonCalled)
        XCTAssertTrue(clientProxy.ignoreUserCalled)
    }
}
