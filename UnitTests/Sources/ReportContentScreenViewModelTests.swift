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
@Suite
struct ReportContentScreenViewModelTests {
    let eventID = "test-id"
    let senderID = "@meany:server.com"
    let reportReason = "I don't like it."
    
    @Test
    func reportContent() async throws {
        // Given the report content view for some content.
        let roomProxy = JoinedRoomProxyMock(.init(name: "test"))
        roomProxy.reportContentReasonReturnValue = .success(())
        let clientProxy = ClientProxyMock(.init())
        let viewModel = ReportContentScreenViewModel(eventID: eventID,
                                                     senderID: senderID,
                                                     roomProxy: roomProxy,
                                                     clientProxy: clientProxy)
        
        // When reporting the content without ignoring the user.
        viewModel.state.bindings.reasonText = reportReason
        viewModel.state.bindings.ignoreUser = false
        viewModel.context.send(viewAction: .submit)
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            action == .submitFinished
        }
        
        try await deferred.fulfill()
   
        // Then the content should be reported, but the user should not be included.
        #expect(roomProxy.reportContentReasonCallsCount == 1, "The content should always be reported.")
        #expect(roomProxy.reportContentReasonReceivedArguments?.eventID == eventID, "The event ID should match the content being reported.")
        #expect(roomProxy.reportContentReasonReceivedArguments?.reason == reportReason, "The reason should match the user input.")
        #expect(clientProxy.ignoreUserCallsCount == 0, "A call to ignore a user should not have been made.")
        #expect(clientProxy.ignoreUserReceivedUserID == nil, "The sender shouldn't have been ignored.")
    }
    
    @Test
    func reportIgnoringSender() async throws {
        // Given the report content view for some content.
        let roomProxy = JoinedRoomProxyMock(.init(name: "test"))
        roomProxy.reportContentReasonReturnValue = .success(())
        let clientProxy = ClientProxyMock(.init())
        let viewModel = ReportContentScreenViewModel(eventID: eventID,
                                                     senderID: senderID,
                                                     roomProxy: roomProxy,
                                                     clientProxy: clientProxy)
        
        // When reporting the content and also ignoring the user.
        viewModel.state.bindings.reasonText = reportReason
        viewModel.state.bindings.ignoreUser = true

        viewModel.context.send(viewAction: .submit)
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            action == .submitFinished
        }
        
        try await deferred.fulfill()
        
        // Then the content should be reported, and the user should be ignored.
        #expect(roomProxy.reportContentReasonCallsCount == 1, "The content should always be reported.")
        #expect(roomProxy.reportContentReasonReceivedArguments?.eventID == eventID, "The event ID should match the content being reported.")
        #expect(roomProxy.reportContentReasonReceivedArguments?.reason == reportReason, "The reason should match the user input.")
        #expect(clientProxy.ignoreUserCallsCount == 1, "A call should have been made to ignore the sender.")
        #expect(clientProxy.ignoreUserReceivedUserID == senderID, "The ignored user ID should match the sender.")
    }
}
