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

import Combine
import Foundation
import XCTest

class BugReportServiceTests: XCTestCase {
    var bugReportService: BugReportServiceMock!

    override func setUpWithError() throws {
        bugReportService = BugReportServiceMock()
        bugReportService.underlyingCrashedLastRun = false
        bugReportService.submitBugReportProgressListenerReturnValue = .success(SubmitBugReportResponse(reportUrl: "https://www.example.com/123"))
    }

    func testInitialStateWithMockService() {
        XCTAssertFalse(bugReportService.crashedLastRun)
    }

    func testSubmitBugReportWithMockService() async throws {
        let bugReport = BugReport(userID: "@mock:client.com",
                                  deviceID: nil,
                                  text: "i cannot send message",
                                  includeLogs: true,
                                  includeCrashLog: true,
                                  githubLabels: [],
                                  files: [])
        let progressSubject = CurrentValueSubject<Double, Never>(0.0)
        let response = try await bugReportService.submitBugReport(bugReport, progressListener: progressSubject).get()
        XCTAssertFalse(response.reportUrl.isEmpty)
    }
    
    func testInitialStateWithRealService() throws {
        let service = BugReportService(withBaseURL: "https://www.example.com",
                                       sentryURL: "https://1234@sentry.com/1234",
                                       applicationId: "mock_app_id",
                                       maxUploadSize: ServiceLocator.shared.settings.bugReportMaxUploadSize,
                                       session: .mock)
        XCTAssertFalse(service.crashedLastRun)
    }
    
    @MainActor func testSubmitBugReportWithRealService() async throws {
        let service = BugReportService(withBaseURL: "https://www.example.com",
                                       sentryURL: "https://1234@sentry.com/1234",
                                       applicationId: "mock_app_id",
                                       maxUploadSize: ServiceLocator.shared.settings.bugReportMaxUploadSize,
                                       session: .mock)

        let bugReport = BugReport(userID: "@mock:client.com",
                                  deviceID: nil,
                                  text: "i cannot send message",
                                  includeLogs: true,
                                  includeCrashLog: true,
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
