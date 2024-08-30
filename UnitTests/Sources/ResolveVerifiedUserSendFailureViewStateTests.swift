//
// Copyright 2024 New Vector Ltd
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.
//

import XCTest

@testable import ElementX

@MainActor
class ResolveVerifiedUserSendFailureViewStateTests: XCTestCase {
    var viewModel: TimelineViewModel!
    var context: TimelineViewModel.Context!
    var viewState: ResolveVerifiedUserSendFailureViewState!
    
    override func setUp() async throws {
        viewModel = .mock
        context = viewModel.context
    }
    
    func testUnsignedDevice() async throws {
        // Given a failure where a single user has an unverified device
        let userID = "@alice:matrix.org"
        viewState = makeViewState(with: .hasUnsignedDevice(devices: [userID: ["DEVICE1"]]))
        XCTAssertNotNil(context.sendFailureInfo)
        
        try await verifyResolving(userIDs: [userID])
    }
    
    func testMultipleUnsignedDevices() async throws {
        // Given a failure where a multiple users have unverified devices.
        let userIDs = ["@alice:matrix.org", "@bob:matrix.org", "@charlie:matrix.org"]
        let devices = Dictionary(uniqueKeysWithValues: userIDs.map { (key: $0, value: ["DEVICE1, DEVICE2"]) })
        viewState = makeViewState(with: .hasUnsignedDevice(devices: devices))
        XCTAssertNotNil(context.sendFailureInfo)
        
        try await verifyResolving(userIDs: userIDs, assertStrings: false)
    }
    
    func testChangedIdentity() async throws {
        // Given a failure where a single user's identity has changed.
        let userID = "@alice:matrix.org"
        viewState = makeViewState(with: .changedIdentity(users: [userID]))
        XCTAssertNotNil(context.sendFailureInfo)
        
        try await verifyResolving(userIDs: [userID])
    }
    
    func testMultipleChangedIdentities() async throws {
        // Given a failure where a multiple users have unverified devices.
        let userIDs = ["@alice:matrix.org", "@bob:matrix.org", "@charlie:matrix.org"]
        viewState = makeViewState(with: .changedIdentity(users: userIDs))
        XCTAssertNotNil(context.sendFailureInfo)
        
        try await verifyResolving(userIDs: userIDs)
    }
    
    // MARK: Helpers
    
    private func makeViewState(with failure: TimelineItemSendFailure.VerifiedUser) -> ResolveVerifiedUserSendFailureViewState {
        let sendFailureInfo = TimelineItemSendFailureInfo(id: .random, failure: failure)
        context.sendFailureInfo = sendFailureInfo
        return ResolveVerifiedUserSendFailureViewState(info: sendFailureInfo, context: context)
    }
    
    private func verifyResolving(userIDs: [String], assertStrings: Bool = true) async throws {
        var remainingUserIDs = userIDs
        
        while remainingUserIDs.count > 1 {
            // Verify that the strings are being updated.
            if assertStrings {
                verifyDisplayName(from: remainingUserIDs)
            }
            
            // When resolving the first failure.
            let deferredFailure = deferFailure(context.$viewState, timeout: 1) { $0.bindings.sendFailureInfo == nil }
            viewState.resolveAndSend()
            try await deferredFailure.fulfill()
            
            // Then the sheet should remain open for the next failure.
            XCTAssertNotNil(context.sendFailureInfo)
            
            remainingUserIDs.removeFirst()
        }
        
        // Verify the final string.
        if assertStrings {
            verifyDisplayName(from: remainingUserIDs)
        }
        
        // When resolving the final failure.
        let deferred = deferFulfillment(context.$viewState) { $0.bindings.sendFailureInfo == nil }
        viewState.resolveAndSend()
        try await deferred.fulfill()
        
        // Then the sheet should be dismissed.
        XCTAssertNil(context.sendFailureInfo)
    }
    
    private func verifyDisplayName(from remainingUserIDs: [String]) {
        guard let userID = remainingUserIDs.first else {
            XCTFail("There should be a user ID to check.")
            return
        }
        
        guard let displayName = context.viewState.members[userID]?.displayName else {
            XCTFail("There should be a matching mock user")
            return
        }
        
        XCTAssertTrue(viewState.title.contains(displayName))
        XCTAssertTrue(viewState.subtitle.contains(displayName))
    }
}
