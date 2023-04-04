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
    enum TestError: Error {
        case testError
    }

    func testInitialState() {
        let viewModel = BugReportViewModel(bugReportService: BugReportServiceMock(),
                                           userID: "@mock.client.com",
                                           deviceID: nil,
                                           screenshot: nil,
                                           isModallyPresented: false)
        let context = viewModel.context
        
        XCTAssertEqual(context.reportText, "")
        XCTAssertNil(context.viewState.screenshot)
        XCTAssertTrue(context.sendingLogsEnabled)
    }
    
    func testClearScreenshot() async throws {
        let viewModel = BugReportViewModel(bugReportService: BugReportServiceMock(),
                                           userID: "@mock.client.com",
                                           deviceID: nil,
                                           screenshot: UIImage.actions,
                                           isModallyPresented: false)
        let context = viewModel.context
        
        context.send(viewAction: .removeScreenshot)
        await context.nextViewState()
        XCTAssertNil(context.viewState.screenshot)
    }
    
    func testAttachScreenshot() async throws {
        let viewModel = BugReportViewModel(bugReportService: BugReportServiceMock(),
                                           userID: "@mock.client.com",
                                           deviceID: nil,
                                           screenshot: nil, isModallyPresented: false)
        let context = viewModel.context
        XCTAssertNil(context.viewState.screenshot)
        context.send(viewAction: .attachScreenshot(UIImage.actions))
        await context.nextViewState()
        XCTAssert(context.viewState.screenshot == UIImage.actions)
    }

    func testSendReportWithSuccess() async throws {
        let mockService = BugReportServiceMock()
        mockService.submitBugReportProgressListenerReturnValue = SubmitBugReportResponse(reportUrl: "https://test.test")
        let viewModel = BugReportViewModel(bugReportService: mockService,
                                           userID: "@mock.client.com",
                                           deviceID: nil,
                                           screenshot: nil, isModallyPresented: false)
        let context = viewModel.context
        var isSuccess = false
        viewModel.callback = { result in
            switch result {
            case .submitFinished:
                isSuccess = true
            default: break
            }
        }
        context.send(viewAction: .submit)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssert(mockService.submitBugReportProgressListenerCallsCount == 1)
        XCTAssert(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport == BugReport(userID: "@mock.client.com", deviceID: nil, text: "", includeLogs: true, includeCrashLog: true, githubLabels: [], files: []))
        XCTAssertTrue(isSuccess)
    }

    func testSendReportWithError() async throws {
        let mockService = BugReportServiceMock()
        mockService.submitBugReportProgressListenerClosure = { _, _ in
            throw TestError.testError
        }
        let viewModel = BugReportViewModel(bugReportService: mockService,
                                           userID: "@mock.client.com",
                                           deviceID: nil,
                                           screenshot: nil, isModallyPresented: false)
        let context = viewModel.context
        var isFailure = false

        viewModel.callback = { result in
            switch result {
            case .submitFailed:
                isFailure = true
            default: break
            }
        }

        context.send(viewAction: .submit)
        try await Task.sleep(for: .milliseconds(100))
        XCTAssert(mockService.submitBugReportProgressListenerCallsCount == 1)
        XCTAssert(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport == BugReport(userID: "@mock.client.com", deviceID: nil, text: "", includeLogs: true, includeCrashLog: true, githubLabels: [], files: []))
        XCTAssertTrue(isFailure)
    }
}
