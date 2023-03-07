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
import Foundation
import XCTest

class BugReportServiceTests: XCTestCase {
    var bugReportService: BugReportServiceProtocolMock!

    override func setUpWithError() throws {
        bugReportService = BugReportServiceProtocolMock()
        bugReportService.underlyingCrashedLastRun = false
        bugReportService.submitBugReportProgressListenerReturnValue = SubmitBugReportResponse(reportUrl: "https://www.example.com/123")
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
        let result = try await bugReportService.submitBugReport(bugReport, progressListener: nil)
        XCTAssertFalse(result.reportUrl.isEmpty)
    }
    
    func testInitialStateWithRealService() throws {
        let service = BugReportService(withBaseURL: URL(staticString: "https://www.example.com"),
                                       sentryURL: URL(staticString: "https://1234@sentry.com/1234"),
                                       applicationId: "mock_app_id",
                                       session: .mock)
        XCTAssertFalse(service.crashedLastRun)
    }
    
    @MainActor func testSubmitBugReportWithRealService() async throws {
        let service = BugReportService(withBaseURL: URL(staticString: "https://www.example.com"),
                                       sentryURL: URL(staticString: "https://1234@sentry.com/1234"),
                                       applicationId: "mock_app_id",
                                       session: .mock)

        let bugReport = BugReport(userID: "@mock:client.com",
                                  deviceID: nil,
                                  text: "i cannot send message",
                                  includeLogs: true,
                                  includeCrashLog: true,
                                  githubLabels: [],
                                  files: [])
        let result = try await service.submitBugReport(bugReport, progressListener: nil)
        
        XCTAssertEqual(result.reportUrl, "https://example.com/123")
    }
}

private class MockURLProtocol: URLProtocol {
    override func startLoading() {
        let response = "{\"report_url\":\"https://example.com/123\"}"
        if let data = response.data(using: .utf8) {
            let urlResponse = URLResponse()
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
