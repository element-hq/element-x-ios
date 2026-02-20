//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing

@Suite
@MainActor
struct ResolveVerifiedUserSendFailureScreenViewModelTests {
    private let roomProxy = JoinedRoomProxyMock(.init())
    
    @Test
    func unsignedDevice() async throws {
        // Given a failure where a single user has an unverified device
        let userID = "@alice:matrix.org"
        let viewModel = makeViewModel(with: .hasUnsignedDevice(devices: [userID: ["DEVICE1"]]))
        
        try await verifyResolving(viewModel: viewModel, userIDs: [userID])
    }
    
    @Test
    func multipleUnsignedDevices() async throws {
        // Given a failure where a multiple users have unverified devices.
        let userIDs = ["@alice:matrix.org", "@bob:matrix.org", "@charlie:matrix.org"]
        let devices = Dictionary(uniqueKeysWithValues: userIDs.map { ($0, ["DEVICE1, DEVICE2"]) })
        let viewModel = makeViewModel(with: .hasUnsignedDevice(devices: devices))
        
        try await verifyResolving(viewModel: viewModel, userIDs: userIDs, assertStrings: false)
    }
    
    @Test
    func changedIdentity() async throws {
        // Given a failure where a single user's identity has changed.
        let userID = "@alice:matrix.org"
        let viewModel = makeViewModel(with: .changedIdentity(users: [userID]))
        
        try await verifyResolving(viewModel: viewModel, userIDs: [userID])
    }
    
    @Test
    func multipleChangedIdentities() async throws {
        // Given a failure where a multiple users have unverified devices.
        let userIDs = ["@alice:matrix.org", "@bob:matrix.org", "@charlie:matrix.org"]
        let viewModel = makeViewModel(with: .changedIdentity(users: userIDs))
        
        try await verifyResolving(viewModel: viewModel, userIDs: userIDs)
    }
    
    // MARK: Helpers
    
    private func makeViewModel(with failure: TimelineItemSendFailure.VerifiedUser) -> ResolveVerifiedUserSendFailureScreenViewModel {
        ResolveVerifiedUserSendFailureScreenViewModel(failure: failure,
                                                      sendHandle: .mock,
                                                      roomProxy: roomProxy,
                                                      userIndicatorController: UserIndicatorControllerMock())
    }
    
    private func verifyResolving(viewModel: ResolveVerifiedUserSendFailureScreenViewModel, userIDs: [String], assertStrings: Bool = true) async throws {
        var remainingUserIDs = userIDs
        let context = viewModel.context
        
        while remainingUserIDs.count > 1 {
            // Verify that the strings are being updated.
            if assertStrings {
                try verifyDisplayName(context: context, from: remainingUserIDs)
            }
            
            // When resolving the first failure.
            let deferredFailure = deferFailure(viewModel.actionsPublisher, timeout: .seconds(1)) { $0 == .dismiss }
            context.send(viewAction: .resolveAndResend)
            
            // Then the sheet should remain open for the next failure.
            try await deferredFailure.fulfill()
            
            remainingUserIDs.removeFirst()
        }
        
        // Verify the final string.
        if assertStrings {
            try verifyDisplayName(context: context, from: remainingUserIDs)
        }
        
        // When resolving the final failure.
        let deferred = deferFulfillment(viewModel.actionsPublisher) { $0 == .dismiss }
        context.send(viewAction: .resolveAndResend)
        
        // Then the sheet should be dismissed.
        try await deferred.fulfill()
    }
    
    private func verifyDisplayName(context: ResolveVerifiedUserSendFailureScreenViewModel.Context, from remainingUserIDs: [String]) throws {
        let userID = try #require(remainingUserIDs.first, "There should be a user ID to check.")
        let displayName = try #require(roomProxy.membersPublisher.value.first { $0.userID == userID }?.displayName,
                                       "There should be a matching mock user")
        
        #expect(context.viewState.title.contains(displayName))
        #expect(context.viewState.subtitle.contains(displayName))
    }
}
