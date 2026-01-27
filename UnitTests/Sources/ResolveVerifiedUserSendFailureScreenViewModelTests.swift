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
class ResolveVerifiedUserSendFailureScreenViewModelTests: XCTestCase {
    let roomProxy = JoinedRoomProxyMock(.init())
    var viewModel: ResolveVerifiedUserSendFailureScreenViewModel!
    var context: ResolveVerifiedUserSendFailureScreenViewModel.Context {
        viewModel.context
    }
    
    func testUnsignedDevice() async throws {
        // Given a failure where a single user has an unverified device
        let userID = "@alice:matrix.org"
        viewModel = makeViewModel(with: .hasUnsignedDevice(devices: [userID: ["DEVICE1"]]))
        
        try await verifyResolving(userIDs: [userID])
    }
    
    func testMultipleUnsignedDevices() async throws {
        // Given a failure where a multiple users have unverified devices.
        let userIDs = ["@alice:matrix.org", "@bob:matrix.org", "@charlie:matrix.org"]
        let devices = Dictionary(uniqueKeysWithValues: userIDs.map { ($0, ["DEVICE1, DEVICE2"]) })
        viewModel = makeViewModel(with: .hasUnsignedDevice(devices: devices))
        
        try await verifyResolving(userIDs: userIDs, assertStrings: false)
    }
    
    func testChangedIdentity() async throws {
        // Given a failure where a single user's identity has changed.
        let userID = "@alice:matrix.org"
        viewModel = makeViewModel(with: .changedIdentity(users: [userID]))
        
        try await verifyResolving(userIDs: [userID])
    }
    
    func testMultipleChangedIdentities() async throws {
        // Given a failure where a multiple users have unverified devices.
        let userIDs = ["@alice:matrix.org", "@bob:matrix.org", "@charlie:matrix.org"]
        viewModel = makeViewModel(with: .changedIdentity(users: userIDs))
        
        try await verifyResolving(userIDs: userIDs)
    }
    
    // MARK: Helpers
    
    private func makeViewModel(with failure: TimelineItemSendFailure.VerifiedUser) -> ResolveVerifiedUserSendFailureScreenViewModel {
        ResolveVerifiedUserSendFailureScreenViewModel(failure: failure,
                                                      sendHandle: .mock,
                                                      roomProxy: roomProxy,
                                                      userIndicatorController: UserIndicatorControllerMock())
    }
    
    private func verifyResolving(userIDs: [String], assertStrings: Bool = true) async throws {
        var remainingUserIDs = userIDs
        
        while remainingUserIDs.count > 1 {
            // Verify that the strings are being updated.
            if assertStrings {
                verifyDisplayName(from: remainingUserIDs)
            }
            
            // When resolving the first failure.
            let deferredFailure = deferFailure(viewModel.actionsPublisher, timeout: 1) { $0 == .dismiss }
            context.send(viewAction: .resolveAndResend)
            
            // Then the sheet should remain open for the next failure.
            try await deferredFailure.fulfill()
            
            remainingUserIDs.removeFirst()
        }
        
        // Verify the final string.
        if assertStrings {
            verifyDisplayName(from: remainingUserIDs)
        }
        
        // When resolving the final failure.
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .dismiss }
        context.send(viewAction: .resolveAndResend)
        
        // Then the sheet should be dismissed.
        try await deferred.fulfill()
    }
    
    private func verifyDisplayName(from remainingUserIDs: [String]) {
        guard let userID = remainingUserIDs.first else {
            XCTFail("There should be a user ID to check.")
            return
        }
        
        guard let displayName = roomProxy.membersPublisher.value.first(where: { $0.userID == userID })?.displayName else {
            XCTFail("There should be a matching mock user")
            return
        }
        
        XCTAssertTrue(context.viewState.title.contains(displayName))
        XCTAssertTrue(context.viewState.subtitle.contains(displayName))
    }
}
