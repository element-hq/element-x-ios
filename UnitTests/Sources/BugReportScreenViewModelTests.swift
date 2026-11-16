//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Testing
import UIKit

@MainActor
struct BugReportScreenViewModelTests {
    let logFiles: [URL] = [URL(filePath: "/path/to/file1.log"), URL(filePath: "/path/to/file2.log")]
    
    enum TestError: Error {
        case testError
    }
    
    @Test("The screen starts empty with logs included")
    func initialState() {
        let clientProxy = ClientProxyMock(.init(userID: "@mock.client.com"))
        let viewModel = BugReportScreenViewModel(flow: .userSession(UserSessionMock(.init(clientProxy: clientProxy))),
                                                 bugReportService: BugReportServiceMock(),
                                                 bugReportHook: DefaultBugReportHook(),
                                                 logFiles: logFiles,
                                                 screenshot: nil,
                                                 isModallyPresented: false)
        let context = viewModel.context
        
        #expect(context.reportText == "")
        #expect(context.viewState.screenshot == nil)
        #expect(context.includeLogs)
    }
    
    @Test("Removing the screenshot clears it")
    func clearScreenshot() {
        let clientProxy = ClientProxyMock(.init(userID: "@mock.client.com"))
        let viewModel = BugReportScreenViewModel(flow: .userSession(UserSessionMock(.init(clientProxy: clientProxy))),
                                                 bugReportService: BugReportServiceMock(),
                                                 bugReportHook: DefaultBugReportHook(),
                                                 logFiles: logFiles,
                                                 screenshot: UIImage.actions,
                                                 isModallyPresented: false)
        let context = viewModel.context
        
        context.send(viewAction: .removeScreenshot)
        #expect(context.viewState.screenshot == nil)
    }
    
    @Test("Attaching a screenshot sets it")
    func attachScreenshot() {
        let clientProxy = ClientProxyMock(.init(userID: "@mock.client.com"))
        let viewModel = BugReportScreenViewModel(flow: .userSession(UserSessionMock(.init(clientProxy: clientProxy))),
                                                 bugReportService: BugReportServiceMock(),
                                                 bugReportHook: DefaultBugReportHook(),
                                                 logFiles: logFiles,
                                                 screenshot: nil,
                                                 isModallyPresented: false)
        let context = viewModel.context
        #expect(context.viewState.screenshot == nil)
        context.send(viewAction: .attachScreenshot(UIImage.actions))
        #expect(context.viewState.screenshot == UIImage.actions)
    }
    
    @Test("A successful submission sends the session's details and logs")
    func sendReportWithSuccess() async throws {
        let mockService = BugReportServiceMock()
        mockService.submitBugReportFlowProgressListenerClosure = { _, _, _ in
            await Task.yield()
            return .success(SubmitBugReportResponse(reportURL: "https://test.test"))
        }
        
        let clientProxy = ClientProxyMock(.init(userID: "@mock.client.com", deviceID: "ABCDEFGH"))
        clientProxy.ed25519Base64ReturnValue = "THEEDKEYKEY"
        clientProxy.curve25519Base64ReturnValue = "THECURVEKEYKEY"
        
        let viewModel = BugReportScreenViewModel(flow: .userSession(UserSessionMock(.init(clientProxy: clientProxy))),
                                                 bugReportService: mockService,
                                                 bugReportHook: DefaultBugReportHook(),
                                                 logFiles: logFiles,
                                                 screenshot: nil,
                                                 isModallyPresented: false)
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
        
        #expect(mockService.submitBugReportFlowProgressListenerCallsCount == 1)
        #expect(mockService.submitBugReportFlowProgressListenerReceivedArguments?.bugReport.userID == "@mock.client.com")
        #expect(mockService.submitBugReportFlowProgressListenerReceivedArguments?.bugReport.deviceID == "ABCDEFGH")
        #expect(mockService.submitBugReportFlowProgressListenerReceivedArguments?.bugReport.curve25519 == "THECURVEKEYKEY")
        #expect(mockService.submitBugReportFlowProgressListenerReceivedArguments?.bugReport.ed25519 == "THEEDKEYKEY")
        #expect(mockService.submitBugReportFlowProgressListenerReceivedArguments?.bugReport.text == "This will succeed")
        #expect(mockService.submitBugReportFlowProgressListenerReceivedArguments?.bugReport.logFiles == logFiles)
        #expect(mockService.submitBugReportFlowProgressListenerReceivedArguments?.bugReport.canContact == false)
        #expect(mockService.submitBugReportFlowProgressListenerReceivedArguments?.bugReport.githubLabels == [])
        #expect(mockService.submitBugReportFlowProgressListenerReceivedArguments?.bugReport.files == [])
    }
    
    @Test("A failed submission keeps the report so the user can retry")
    func sendReportWithError() async throws {
        let mockService = BugReportServiceMock()
        mockService.submitBugReportFlowProgressListenerClosure = { _, _, _ in
            .failure(.uploadFailure(TestError.testError))
        }
        
        let clientProxy = ClientProxyMock(.init(userID: "@mock.client.com"))
        let viewModel = BugReportScreenViewModel(flow: .userSession(UserSessionMock(.init(clientProxy: clientProxy))),
                                                 bugReportService: mockService,
                                                 bugReportHook: DefaultBugReportHook(),
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
        
        #expect(mockService.submitBugReportFlowProgressListenerCallsCount == 1)
        #expect(context.reportText == "This will fail", "The bug report should remain in place so the user can retry.")
        #expect(!context.viewState.shouldDisableInteraction, "The user should be able to retry.")
    }
}
