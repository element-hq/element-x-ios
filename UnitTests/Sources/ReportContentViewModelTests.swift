//
// Copyright 2022 New Vector Ltd
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

@testable import ElementX
import XCTest

@MainActor
class ReportContentScreenViewModelTests: XCTestCase {
    let eventID = "test-id"
    let senderID = "@meany:server.com"
    let reportReason = "I don't like it."
    
    func testReportContent() async throws {
        // Given the report content view for some content.
        let roomProxy = RoomProxyMock(with: .init(name: "test"))
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
        XCTAssertEqual(roomProxy.reportContentReasonCallsCount, 1, "The content should always be reported.")
        XCTAssertEqual(roomProxy.reportContentReasonReceivedArguments?.eventID, eventID, "The event ID should match the content being reported.")
        XCTAssertEqual(roomProxy.reportContentReasonReceivedArguments?.reason, reportReason, "The reason should match the user input.")
        XCTAssertEqual(clientProxy.ignoreUserCallsCount, 0, "A call to ignore a user should not have been made.")
        XCTAssertNil(clientProxy.ignoreUserReceivedUserID, "The sender shouldn't have been ignored.")
    }
    
    func testReportIgnoringSender() async throws {
        // Given the report content view for some content.
        let roomProxy = RoomProxyMock(with: .init(name: "test"))
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
        XCTAssertEqual(roomProxy.reportContentReasonCallsCount, 1, "The content should always be reported.")
        XCTAssertEqual(roomProxy.reportContentReasonReceivedArguments?.eventID, eventID, "The event ID should match the content being reported.")
        XCTAssertEqual(roomProxy.reportContentReasonReceivedArguments?.reason, reportReason, "The reason should match the user input.")
        XCTAssertEqual(clientProxy.ignoreUserCallsCount, 1, "A call should have been made to ignore the sender.")
        XCTAssertEqual(clientProxy.ignoreUserReceivedUserID, senderID, "The ignored user ID should match the sender.")
    }
}
