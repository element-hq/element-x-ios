//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX

import Combine
import Foundation
import XCTest

class BugReportServiceTests: XCTestCase {
    var appSettings: AppSettings!
    var bugReportService: BugReportServiceProtocol!

    override func setUpWithError() throws {
        AppSettings.resetAllSettings()
        appSettings = AppSettings()
        appSettings.bugReportRageshakeURL.reset()
        
        let bugReportServiceMock = BugReportServiceMock()
        bugReportServiceMock.underlyingCrashedLastRun = false
        bugReportServiceMock.submitBugReportProgressListenerReturnValue = .success(SubmitBugReportResponse(reportURL: "https://www.example.com/123"))
        bugReportService = bugReportServiceMock
    }
    
    override func tearDown() {
        appSettings.bugReportRageshakeURL.reset()
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
                                  logFiles: [URL(filePath: "/logs/1.log"), URL(filePath: "/logs/2.log")],
                                  canContact: false,
                                  githubLabels: [],
                                  files: [])
        let progressSubject = CurrentValueSubject<Double, Never>(0.0)
        let response = try await bugReportService.submitBugReport(bugReport, progressListener: progressSubject).get()
        let reportURL = try XCTUnwrap(response.reportURL)
        XCTAssertFalse(reportURL.isEmpty)
    }
    
    func testInitialStateWithRealService() throws {
        let urlPublisher: CurrentValueSubject<RageshakeConfiguration, Never> = .init(.url("https://example.com/submit"))
        let service = BugReportService(rageshakeURLPublisher: urlPublisher.asCurrentValuePublisher(),
                                       applicationID: "mock_app_id",
                                       sdkGitSHA: "1234",
                                       maxUploadSize: ServiceLocator.shared.settings.bugReportMaxUploadSize,
                                       session: .mock,
                                       appHooks: AppHooks())
        XCTAssertTrue(service.isEnabled)
        XCTAssertFalse(service.crashedLastRun)
    }
    
    func testInitialStateWithRealServiceAndDisabled() throws {
        let urlPublisher: CurrentValueSubject<RageshakeConfiguration, Never> = .init(.disabled)
        let service = BugReportService(rageshakeURLPublisher: urlPublisher.asCurrentValuePublisher(),
                                       applicationID: "mock_app_id",
                                       sdkGitSHA: "1234",
                                       maxUploadSize: ServiceLocator.shared.settings.bugReportMaxUploadSize,
                                       session: .mock,
                                       appHooks: AppHooks())
        XCTAssertFalse(service.isEnabled)
        XCTAssertFalse(service.crashedLastRun)
    }
    
    @MainActor func testSubmitBugReportWithRealService() async throws {
        let urlPublisher: CurrentValueSubject<RageshakeConfiguration, Never> = .init(.url("https://example.com/submit"))
        let service = BugReportService(rageshakeURLPublisher: urlPublisher.asCurrentValuePublisher(),
                                       applicationID: "mock_app_id",
                                       sdkGitSHA: "1234",
                                       maxUploadSize: ServiceLocator.shared.settings.bugReportMaxUploadSize,
                                       session: .mock,
                                       appHooks: AppHooks())

        let bugReport = BugReport(userID: "@mock:client.com",
                                  deviceID: nil,
                                  ed25519: nil,
                                  curve25519: nil,
                                  text: "i cannot send message",
                                  logFiles: Tracing.logFiles,
                                  canContact: false,
                                  githubLabels: [],
                                  files: [])
        let progressSubject = CurrentValueSubject<Double, Never>(0.0)
        let response = try await service.submitBugReport(bugReport, progressListener: progressSubject).get()
        
        XCTAssertEqual(response.reportURL, "https://example.com/123")
    }
    
    @MainActor func testConfigurations() async throws {
        guard case let .url(initialURL) = appSettings.bugReportRageshakeURL.publisher.value else {
            XCTFail("Unexpected initial configuration.")
            return
        }
        
        let service = BugReportService(rageshakeURLPublisher: appSettings.bugReportRageshakeURL.publisher,
                                       applicationID: "mock_app_id",
                                       sdkGitSHA: "1234",
                                       maxUploadSize: ServiceLocator.shared.settings.bugReportMaxUploadSize,
                                       session: .mock,
                                       appHooks: AppHooks())
        XCTAssertTrue(service.isEnabled)
        
        appSettings.bugReportRageshakeURL.applyRemoteValue(.disabled)
        XCTAssertFalse(service.isEnabled)
        
        appSettings.bugReportRageshakeURL.applyRemoteValue(.url("https://bugs.server.net/submit"))
        XCTAssertTrue(service.isEnabled)

        let bugReport = BugReport(userID: "@mock:client.com",
                                  deviceID: nil,
                                  ed25519: nil,
                                  curve25519: nil,
                                  text: "i cannot send message",
                                  logFiles: Tracing.logFiles,
                                  canContact: false,
                                  githubLabels: [],
                                  files: [])
        let progressSubject = CurrentValueSubject<Double, Never>(0.0)
        let customConfigurationResponse = try await service.submitBugReport(bugReport, progressListener: progressSubject).get()
        
        XCTAssertEqual(customConfigurationResponse.reportURL, "https://bugs.server.net/123")
        
        appSettings.bugReportRageshakeURL.reset()
        XCTAssertTrue(service.isEnabled)
        
        let defaultConfigurationResponse = try await service.submitBugReport(bugReport, progressListener: progressSubject).get()
        
        XCTAssertEqual(defaultConfigurationResponse.reportURL, initialURL.absoluteString.replacingOccurrences(of: "submit", with: "123"))
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
        guard let url = request.url else { return }
        let reportURL = url.deletingLastPathComponent().appending(path: "123")
        let response = "{\"report_url\":\"\(reportURL.absoluteString)\"}"
        
        if let data = response.data(using: .utf8),
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
