//
// Copyright 2025 Element Creations Ltd.
// Copyright 2022-2025 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Combine
@testable import ElementX
import Foundation
import Testing

@MainActor
final class BugReportServiceTests {
    var bugReportService: BugReportServiceProtocol!
    
    init() throws {
        bugReportService = BugReportServiceMock(.init())
    }
    
    @Test("The mock service starts without a crash event")
    func initialStateWithMockService() {
        #expect(bugReportService.lastCrashEventIDSubject.value == nil)
    }
    
    @Test("The mock service returns a report URL")
    func submitBugReportWithMockService() async throws {
        let response = try await bugReportService.submitBugReport(.mock(logFiles: [URL(filePath: "/logs/1.log"), URL(filePath: "/logs/2.log")]),
                                                                  flow: .authentication(.url("https://example.com/submit")),
                                                                  progressListener: CurrentValueSubject<Double, Never>(0.0)).get()
        let reportURL = try #require(response.reportURL)
        #expect(!reportURL.isEmpty)
    }
    
    @Test("The real service starts without a crash event")
    func initialStateWithRealService() {
        let service = makeService()
        #expect(service.lastCrashEventIDSubject.value == nil)
    }
    
    @Test("A report during authentication is sent to the given rageshake server")
    func submitBugReportDuringAuthentication() async throws {
        let service = makeService()
        
        let response = try await service.submitBugReport(.mock(), flow: .authentication(.url("https://example.com/submit")), progressListener: CurrentValueSubject<Double, Never>(0.0)).get()
        
        #expect(response.reportURL == "https://example.com/123")
    }
    
    @Test("A report from a user session is sent to the account's rageshake server")
    func submitBugReportWithSession() async throws {
        let service = makeService()
        let userSession = UserSessionMock(.init())
        userSession.userSettings.account.bugReportRageshakeConfiguration.applyRemoteValue(.url("https://bugs.server.net/submit"))
        
        let response = try await service.submitBugReport(.mock(), flow: .userSession(userSession), progressListener: CurrentValueSubject<Double, Never>(0.0)).get()
        
        #expect(response.reportURL == "https://bugs.server.net/123")
    }
    
    // MARK: - Helpers
    
    private func makeService() -> BugReportService {
        BugReportService(applicationID: "mock_app_id",
                         sdkGitSHA: "1234",
                         session: .mock,
                         appHooks: AppHooks())
    }
}

private extension BugReport {
    static func mock(logFiles: [URL] = Tracing.logFiles) -> BugReport {
        BugReport(userID: "@mock:client.com",
                  deviceID: nil,
                  ed25519: nil,
                  curve25519: nil,
                  text: "i cannot send message",
                  logFiles: logFiles,
                  canContact: false,
                  githubLabels: [],
                  files: [])
    }
}

private nonisolated class MockURLProtocol: URLProtocol {
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
        return URLSession(configuration: configuration)
    }
}
