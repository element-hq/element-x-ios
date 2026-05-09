//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

@testable import ElementX
import Foundation
import Testing

final class ClassicAppMediaLoaderTests {
    let account: ClassicAppAccount
    let mediaLoader: ClassicAppMediaLoader
    let urlSession: URLSession
    
    init() throws {
        account = ClassicAppAccount(userID: "@alice:matrix.org",
                                    displayName: nil,
                                    avatarURL: nil,
                                    serverName: "matrix.org",
                                    homeserverURL: "https://matrix-client.matrix.org",
                                    cryptoStoreURL: .temporaryDirectory,
                                    cryptoStorePassphrase: "",
                                    accessToken: MockURLProtocol.accessToken)
        
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        urlSession = URLSession(configuration: configuration)
        
        mediaLoader = ClassicAppMediaLoader(classicAppAccount: account, urlSession: urlSession)
    }
    
    // MARK: - Images
    
    @Test
    func loadMediaContent() async throws {
        let source = try MediaSourceProxy(url: MockURLProtocol.mxcURL, mimeType: nil)
        let data = try await mediaLoader.loadMediaContentForSource(source)
        #expect(data == MockURLProtocol.downloadData)
    }
    
    @Test
    func loadMediaContentWithInvalidToken() async throws {
        let accountWithoutToken = ClassicAppAccount(userID: "@bob:matrix.org",
                                                    displayName: nil,
                                                    avatarURL: nil,
                                                    serverName: "matrix.org",
                                                    homeserverURL: "https://matrix-client.matrix.org",
                                                    cryptoStoreURL: .temporaryDirectory,
                                                    cryptoStorePassphrase: "",
                                                    accessToken: "wrongToken")
        let loaderWithoutToken = ClassicAppMediaLoader(classicAppAccount: accountWithoutToken, urlSession: urlSession)
        
        let source = try MediaSourceProxy(url: MockURLProtocol.mxcURL, mimeType: nil)
        await #expect(throws: MediaLoaderError.unexpectedResponse) {
            try await loaderWithoutToken.loadMediaContentForSource(source)
        }
    }
    
    @Test
    func loadMediaContentWith404() async throws {
        let source = try MediaSourceProxy(url: MockURLProtocol.notFoundMXCURL, mimeType: nil)
        await #expect(throws: MediaLoaderError.unexpectedResponse) {
            try await mediaLoader.loadMediaContentForSource(source)
        }
    }
    
    // MARK: - Thumbnails
    
    @Test
    func loadMediaThumbnail() async throws {
        let source = try MediaSourceProxy(url: MockURLProtocol.mxcURL, mimeType: nil)
        let data = try await mediaLoader.loadMediaThumbnailForSource(source, width: 100, height: 100)
        #expect(data == MockURLProtocol.thumbnailData)
    }
    
    @Test
    func loadMediaThumbnailWith404() async throws {
        let source = try MediaSourceProxy(url: MockURLProtocol.notFoundMXCURL, mimeType: nil)
        await #expect(throws: MediaLoaderError.unexpectedResponse) {
            try await mediaLoader.loadMediaThumbnailForSource(source, width: 100, height: 100)
        }
    }
    
    // MARK: - Files (unsupported)
    
    @Test
    func loadMediaFileIsNotSupported() async throws {
        let source = try MediaSourceProxy(url: MockURLProtocol.mxcURL, mimeType: nil)
        await #expect(throws: MediaLoaderError.notSupported) {
            try await mediaLoader.loadMediaFileForSource(source, filename: nil)
        }
    }
    
    // MARK: - URL construction
    
    @Test
    func loadMediaContentBuildsCorrectDownloadURL() async throws {
        let source = try MediaSourceProxy(url: MockURLProtocol.mxcURL, mimeType: nil)
        let capturedRequest = try await mediaLoader.loadMediaContentForSource(source)
        
        // The download path must use the download endpoint with no query string.
        #expect(MockURLProtocol.lastRequest?.url?.path() == "/_matrix/client/v1/media/download/matrix.org/testmediaid")
        #expect(MockURLProtocol.lastRequest?.url?.query() == nil)
        #expect(MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer \(MockURLProtocol.accessToken)")
        _ = capturedRequest
    }
    
    @Test
    func loadMediaThumbnailBuildsCorrectThumbnailURL() async throws {
        let source = try MediaSourceProxy(url: MockURLProtocol.mxcURL, mimeType: nil)
        _ = try await mediaLoader.loadMediaThumbnailForSource(source, width: 320, height: 240)
        
        // The thumbnail path must use the thumbnail endpoint with width/height query items.
        let url = try #require(MockURLProtocol.lastRequest?.url)
        #expect(url.path() == "/_matrix/client/v1/media/thumbnail/matrix.org/testmediaid")
        let queryItems = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems
        #expect(queryItems?.contains(URLQueryItem(name: "width", value: "320")) == true)
        #expect(queryItems?.contains(URLQueryItem(name: "height", value: "240")) == true)
        #expect(MockURLProtocol.lastRequest?.value(forHTTPHeaderField: "Authorization") == "Bearer \(MockURLProtocol.accessToken)")
    }
}

// MARK: - MockURLProtocol

private class MockURLProtocol: URLProtocol {
    /// The MXC URL whose media requests will be served successfully.
    static let mxcURL: URL = "mxc://matrix.org/testmediaid"
    /// The MXC URL whose media requests will return a 404.
    static let notFoundMXCURL: URL = "mxc://matrix.org/notfound"
    
    /// The access token expected on all authenticated requests.
    static let accessToken = "testAccessToken"
    
    /// The data returned for a full-size download of `mxcURL`.
    static let downloadData = Data("download data".utf8)
    /// The data returned for a thumbnail download of `mxcURL`.
    static let thumbnailData = Data("thumbnail data".utf8)
    
    /// The last request handled, for URL/header inspection in tests.
    static var lastRequest: URLRequest?
    
    /// Maps a URL path to a fixed `(statusCode, Data)` response.
    private static let responses: [String: (Int, Data)] = [
        "/_matrix/client/v1/media/download/matrix.org/testmediaid": (200, downloadData),
        "/_matrix/client/v1/media/thumbnail/matrix.org/testmediaid": (200, thumbnailData)
    ]
    
    override func startLoading() {
        MockURLProtocol.lastRequest = request
        
        guard let url = request.url else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        
        let isAuthenticated = request.value(forHTTPHeaderField: "Authorization") == "Bearer \(MockURLProtocol.accessToken)"
        let path = url.path()
        let (statusCode, data) = isAuthenticated ? MockURLProtocol.responses[path] ?? (404, Data()) : (401, Data())
        
        guard let response = HTTPURLResponse(url: url, statusCode: statusCode, httpVersion: nil, headerFields: nil) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: data)
        client?.urlProtocolDidFinishLoading(self)
    }
    
    override func stopLoading() { }
    
    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }
    
    override class func canInit(with request: URLRequest) -> Bool {
        true
    }
}
