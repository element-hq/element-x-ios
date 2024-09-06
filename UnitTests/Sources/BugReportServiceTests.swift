//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

@testable import ElementX

import Combine
import Foundation
import XCTest

class BugReportServiceTests: XCTestCase {
    var bugReportService: BugReportServiceProtocol!

    override func setUpWithError() throws {
        let bugReportServiceMock = BugReportServiceMock()
        bugReportServiceMock.underlyingCrashedLastRun = false
        bugReportServiceMock.submitBugReportProgressListenerReturnValue = .success(SubmitBugReportResponse(reportUrl: "https://www.example.com/123"))
        bugReportService = bugReportServiceMock
    }

    func testInitialStateWithMockService() {
        XCTAssertFalse(bugReportService.crashedLastRun)
    }

    func testSubmitBugReportWithMockService() async throws {
        let bugReport = BugReport(userID: "@mock:client.com",
                                  deviceID: nil,
                                  ed25519: nil,
                                  curve25519: nil,
                                  text: "i cannot send message",
                                  includeLogs: true,
                                  canContact: false,
                                  githubLabels: [],
                                  files: [])
        let progressSubject = CurrentValueSubject<Double, Never>(0.0)
        let response = try await bugReportService.submitBugReport(bugReport, progressListener: progressSubject).get()
        XCTAssertFalse(response.reportUrl.isEmpty)
    }
    
    func testInitialStateWithRealService() throws {
        let service = BugReportService(withBaseURL: "https://www.example.com",
                                       applicationId: "mock_app_id",
                                       sdkGitSHA: "1234",
                                       maxUploadSize: ServiceLocator.shared.settings.bugReportMaxUploadSize,
                                       session: .mock,
                                       appHooks: AppHooks())
        XCTAssertFalse(service.crashedLastRun)
    }
    
    @MainActor func testSubmitBugReportWithRealService() async throws {
        let service = BugReportService(withBaseURL: "https://www.example.com",
                                       applicationId: "mock_app_id",
                                       sdkGitSHA: "1234",
                                       maxUploadSize: ServiceLocator.shared.settings.bugReportMaxUploadSize,
                                       session: .mock,
                                       appHooks: AppHooks())

        let bugReport = BugReport(userID: "@mock:client.com",
                                  deviceID: nil,
                                  ed25519: nil,
                                  curve25519: nil,
                                  text: "i cannot send message",
                                  includeLogs: true,
                                  canContact: false,
                                  githubLabels: [],
                                  files: [])
        let progressSubject = CurrentValueSubject<Double, Never>(0.0)
        let response = try await service.submitBugReport(bugReport, progressListener: progressSubject).get()
        
        XCTAssertEqual(response.reportUrl, "https://example.com/123")
    }
    
    func testLogsMaxSize() {
        // Given a new set of logs
        var logs = BugReportService.Logs(maxFileSize: 1000)
        XCTAssertEqual(logs.zippedSize, 0)
        XCTAssertEqual(logs.originalSize, 0)
        XCTAssertTrue(logs.files.isEmpty)
        
        // When adding new files within the size limit
        logs.appendFile(at: .homeDirectory, zippedSize: 250, originalSize: 1000)
        logs.appendFile(at: .picturesDirectory, zippedSize: 500, originalSize: 2000)
        
        // Then the logs should be included
        XCTAssertEqual(logs.zippedSize, 750)
        XCTAssertEqual(logs.originalSize, 3000)
        XCTAssertEqual(logs.files, [.homeDirectory, .picturesDirectory])
        
        // When adding a new file larger that will exceed the size limit
        logs.appendFile(at: .homeDirectory, zippedSize: 500, originalSize: 2000)
        
        // Then the files shouldn't be included.
        XCTAssertEqual(logs.zippedSize, 750)
        XCTAssertEqual(logs.originalSize, 3000)
        XCTAssertEqual(logs.files, [.homeDirectory, .picturesDirectory])
    }
}

private class MockURLProtocol: URLProtocol {
    override func startLoading() {
        let response = "{\"report_url\":\"https://example.com/123\"}"
        if let data = response.data(using: .utf8),
           let url = request.url,
           let urlResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil) {
            client?.urlProtocol(self, didReceive: urlResponse, cacheStoragePolicy: .allowedInMemoryOnly)
            client?.urlProtocol(self, didLoad: data)
            client?.urlProtocolDidFinishLoading(self)
        }
    }

    override func stopLoading() {
        //  no-op
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
}

private extension URLSession {
    static var mock: URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.protocolClasses = [MockURLProtocol.self] + (configuration.protocolClasses ?? [])
        let result = URLSession(configuration: configuration)
        return result
    }
}
