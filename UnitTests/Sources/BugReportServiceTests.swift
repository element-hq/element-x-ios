//
//  BugReportServiceTests.swift
//  UnitTests
//
//  Created by Ismail on 31.05.2022.
//  Copyright © 2022 element.io. All rights reserved.
//

import Foundation
@testable import ElementX
import XCTest

class BugReportServiceTests: XCTestCase {

    let bugReportService = MockBugReportService()

    func testInitialStateWithMockService() {
        XCTAssertFalse(bugReportService.crashedLastRun)
    }

    func testSubmitBugReportWithMockService() async throws {
        let result = try await bugReportService.submitBugReport(text: "i cannot send message",
                                                                includeLogs: true,
                                                                includeCrashLog: true,
                                                                githubLabels: [],
                                                                files: [])
        XCTAssertFalse(result.reportUrl.isEmpty)
    }

    func testInitialStateWithRealService() throws {
        let service = try BugReportService(withBaseUrlString: "https://www.example.com",
                                           sentryEndpoint: "mock_sentry_dsn",
                                           applicationId: "mock_app_id",
                                           session: .mock)
        XCTAssertFalse(service.crashedLastRun)
    }

    @MainActor func testSubmitBugReportWithRealService() async throws {
        let service = try BugReportService(withBaseUrlString: "https://www.example.com",
                                           sentryEndpoint: "mock_sentry_dsn",
                                           applicationId: "mock_app_id",
                                           session: .mock)

        let result = try await service.submitBugReport(text: "i cannot send message",
                                                       includeLogs: true,
                                                       includeCrashLog: true,
                                                       githubLabels: [],
                                                       files: [])
        
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
        return request
    }

    override class func canInit(with request: URLRequest) -> Bool {
        return true
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
