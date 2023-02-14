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
class BugReportViewModelTests: XCTestCase {
    func testInitialState() {
        let viewModel = BugReportViewModel(bugReportService: MockBugReportService(), screenshot: nil, isModallyPresented: false)
        let context = viewModel.context

        XCTAssertEqual(context.reportText, "")
        XCTAssertNil(context.viewState.screenshot)
        XCTAssertTrue(context.sendingLogsEnabled)
    }

    func testClearScreenshot() async throws {
        let viewModel = BugReportViewModel(bugReportService: MockBugReportService(), screenshot: UIImage.actions, isModallyPresented: false)
        let context = viewModel.context

        context.send(viewAction: .removeScreenshot)
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssertNil(context.viewState.screenshot)
    }

    func testAttachScreenshot() async throws {
        let viewModel = BugReportViewModel(bugReportService: MockBugReportService(), screenshot: nil, isModallyPresented: false)
        let context = viewModel.context
        XCTAssertNil(context.viewState.screenshot)
        context.send(viewAction: .attachScreenshot(UIImage.actions))
        try await Task.sleep(nanoseconds: 100_000_000)
        XCTAssert(context.viewState.screenshot == UIImage.actions)
    }
}
