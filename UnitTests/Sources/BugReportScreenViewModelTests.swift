//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import XCTest

@testable import ElementX

@MainActor
class BugReportScreenViewModelTests: XCTestCase {
    enum TestError: Error {
        case testError
    }
    
    func testInitialState() {
        let clientProxy = ClientProxyMock(.init(userID: "@mock.client.com"))
        let viewModel = BugReportScreenViewModel(bugReportService: BugReportServiceMock(),
                                                 clientProxy: clientProxy,
                                                 screenshot: nil,
                                                 isModallyPresented: false)
        let context = viewModel.context
        
        XCTAssertEqual(context.reportText, "")
        XCTAssertNil(context.viewState.screenshot)
        XCTAssertTrue(context.sendingLogsEnabled)
    }
    
    func testClearScreenshot() async throws {
        let clientProxy = ClientProxyMock(.init(userID: "@mock.client.com"))
        let viewModel = BugReportScreenViewModel(bugReportService: BugReportServiceMock(),
                                                 clientProxy: clientProxy,
                                                 screenshot: UIImage.actions,
                                                 isModallyPresented: false)
        let context = viewModel.context
        
        context.send(viewAction: .removeScreenshot)
        XCTAssertNil(context.viewState.screenshot)
    }
    
    func testAttachScreenshot() async throws {
        let clientProxy = ClientProxyMock(.init(userID: "@mock.client.com"))
        let viewModel = BugReportScreenViewModel(bugReportService: BugReportServiceMock(),
                                                 clientProxy: clientProxy,
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
        
        let clientProxy = ClientProxyMock(.init(userID: "@mock.client.com", deviceID: "ABCDEFGH"))
        clientProxy.ed25519Base64ReturnValue = "THEEDKEYKEY"
        clientProxy.curve25519Base64ReturnValue = "THECURVEKEYKEY"
        
        let viewModel = BugReportScreenViewModel(bugReportService: mockService,
                                                 clientProxy: clientProxy,
                                                 screenshot: nil, isModallyPresented: false)
        let context = viewModel.context
        context.reportText = "This will succeed"
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .submitFinished:
                return true
            default:
                return false
            }
        }
        
        context.send(viewAction: .submit)
        try await deferred.fulfill()
                
        XCTAssert(mockService.submitBugReportProgressListenerCallsCount == 1)
        XCTAssertEqual(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport.userID, "@mock.client.com")
        XCTAssertEqual(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport.deviceID, "ABCDEFGH")
        XCTAssertEqual(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport.curve25519, "THECURVEKEYKEY")
        XCTAssertEqual(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport.ed25519, "THEEDKEYKEY")
        XCTAssertEqual(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport.text, "This will succeed")
        XCTAssertEqual(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport.includeLogs, true)
        XCTAssertEqual(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport.canContact, false)
        XCTAssertEqual(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport.githubLabels, [])
        XCTAssertEqual(mockService.submitBugReportProgressListenerReceivedArguments?.bugReport.files, [])
    }

    func testSendReportWithError() async throws {
        let mockService = BugReportServiceMock()
        mockService.submitBugReportProgressListenerClosure = { _, _ in
            .failure(.uploadFailure(TestError.testError))
        }
        
        let clientProxy = ClientProxyMock(.init(userID: "@mock.client.com"))
        let viewModel = BugReportScreenViewModel(bugReportService: mockService,
                                                 clientProxy: clientProxy,
                                                 screenshot: nil, isModallyPresented: false)
        let context = viewModel.context
        context.reportText = "This will fail"
        
        let deferred = deferFulfillment(viewModel.actions) { action in
            switch action {
            case .submitFailed:
                return true
            default:
                return false
            }
        }
        
        context.send(viewAction: .submit)
        try await deferred.fulfill()
        
        XCTAssert(mockService.submitBugReportProgressListenerCallsCount == 1)
        XCTAssertEqual(context.reportText, "This will fail", "The bug report should remain in place so the user can retry.")
        XCTAssertFalse(context.viewState.shouldDisableInteraction, "The user should be able to retry.")
    }
}
