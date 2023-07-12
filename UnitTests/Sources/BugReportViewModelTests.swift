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
        let viewModel = BugReportScreenViewModel(bugReportService: BugReportServiceMock(),
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
        let viewModel = BugReportScreenViewModel(bugReportService: BugReportServiceMock(),
                                                 userID: "@mock.client.com",
                                                 deviceID: nil,
                                                 screenshot: UIImage.actions,
                                                 isModallyPresented: false)
        let context = viewModel.context
        
        context.send(viewAction: .removeScreenshot)
        XCTAssertNil(context.viewState.screenshot)
    }
    
    func testAttachScreenshot() async throws {
        let viewModel = BugReportScreenViewModel(bugReportService: BugReportServiceMock(),
                                                 userID: "@mock.client.com",
                                                 deviceID: nil,
                                                 screenshot: nil, isModallyPresented: false)
        let context = viewModel.context
        XCTAssertNil(context.viewState.screenshot)
        context.send(viewAction: .attachScreenshot(UIImage.actions))
        XCTAssert(context.viewState.screenshot == UIImage.actions)
    }
    
    func testSendReportWithSuccess() async throws {
        let mockService = BugReportServiceMock()
        mockService.submitBugReportProgressListenerClosure = { _, _ in
            await Task.yield()
            return .success(SubmitBugReportResponse(reportUrl: "https://test.test"))
        }
        let viewModel = BugReportScreenViewModel(bugReportService: mockService,
                                                 userID: "@mock.client.com",
                                                 deviceID: nil,
                                                 screenshot: nil, isModallyPresented: false)
        let context = viewModel.context
        let deferred = deferFulfillment(viewModel.actions.collect(2).first())
        context.send(viewAction: .submit)
        let actions = try await deferred.fulfill()
        
        guard case .submitStarted = actions[0] else {
            return XCTFail("Action 1 was not .submitFailed")
        }
        
        guard case .submitFinished = actions[1] else {
            return XCTFail("Action 2 was not .submitFinished")
        }
        
        XCTAssert(mockService.submitBugReportProgressListenerCallsCount == 1)
        XCTAssert(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport == BugReport(userID: "@mock.client.com", deviceID: nil, text: "", includeLogs: true, includeCrashLog: true, canContact: false, githubLabels: [], files: []))
    }

    func testSendReportWithError() async throws {
        let mockService = BugReportServiceMock()
        mockService.submitBugReportProgressListenerClosure = { _, _ in
            .failure(.uploadFailure(TestError.testError))
        }
        let viewModel = BugReportScreenViewModel(bugReportService: mockService,
                                                 userID: "@mock.client.com",
                                                 deviceID: nil,
                                                 screenshot: nil, isModallyPresented: false)
        
        let deferred = deferFulfillment(viewModel.actions.collect(2).first())
        let context = viewModel.context
        context.send(viewAction: .submit)
        let actions = try await deferred.fulfill()

        guard case .submitStarted = actions[0] else {
            return XCTFail("Action 1 was not .submitFailed")
        }
        
        guard case .submitFailed = actions[1] else {
            return XCTFail("Action 2 was not .submitFailed")
        }
        
        XCTAssert(mockService.submitBugReportProgressListenerCallsCount == 1)
        XCTAssert(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport == BugReport(userID: "@mock.client.com", deviceID: nil, text: "", includeLogs: true, includeCrashLog: true, canContact: false, githubLabels: [], files: []))
    }
}
