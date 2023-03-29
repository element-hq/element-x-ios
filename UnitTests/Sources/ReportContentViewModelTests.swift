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

import XCTest

@testable import ElementX

@MainActor
class ReportContentScreenViewModelTests: XCTestCase {
    let itemID = "test-id"
    let senderID = "@meany:server.com"
    let reportReason = "I don't like it."
    
    func testReportContent() async {
        // Given the report content view for some content.
        let roomProxy = RoomProxyMock(with: .init(displayName: "test"))
        roomProxy.reportContentReasonIgnoringReturnValue = .success(())
        
        let viewModel = ReportContentViewModel(itemID: itemID,
                                               senderID: senderID,
                                               roomProxy: roomProxy)
        
        // When reporting the content without ignoring the user.
        viewModel.state.bindings.reasonText = reportReason
        viewModel.state.bindings.ignoreUser = false
        
        viewModel.context.send(viewAction: .submit)
        await Task.yield()
        
        // Then the content should be reported, but the user should not be included.
        XCTAssertEqual(roomProxy.reportContentReasonIgnoringCallsCount, 1)
        XCTAssertEqual(roomProxy.reportContentReasonIgnoringReceivedArguments?.eventID, itemID, "The event ID should match the content being reported.")
        XCTAssertEqual(roomProxy.reportContentReasonIgnoringReceivedArguments?.reason, reportReason, "The reason should match the user input.")
        XCTAssertNil(roomProxy.reportContentReasonIgnoringReceivedArguments?.senderID, "The sender shouldn't be included as they aren't being ignored.")
    }
    
    func testReportIgnoringSender() async {
        // Given the report content view for some content.
        let roomProxy = RoomProxyMock(with: .init(displayName: "test"))
        roomProxy.reportContentReasonIgnoringReturnValue = .success(())
        
        let viewModel = ReportContentViewModel(itemID: itemID,
                                               senderID: senderID,
                                               roomProxy: roomProxy)
        
        // When reporting the content and also ignoring the user.
        viewModel.state.bindings.reasonText = reportReason
        viewModel.state.bindings.ignoreUser = true
        
        viewModel.context.send(viewAction: .submit)
        await Task.yield()
        
        // Then the content should be reported, and the user should be included in the report.
        XCTAssertEqual(roomProxy.reportContentReasonIgnoringCallsCount, 1)
        
        XCTAssertEqual(roomProxy.reportContentReasonIgnoringReceivedArguments?.eventID, itemID, "The event ID should match the content being reported.")
        XCTAssertEqual(roomProxy.reportContentReasonIgnoringReceivedArguments?.reason, reportReason, "The reason should match the user input.")
        XCTAssertEqual(roomProxy.reportContentReasonIgnoringReceivedArguments?.senderID, senderID, "The sender should be included so that they are ignored.")
    }
}
