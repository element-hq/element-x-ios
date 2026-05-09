//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import SwiftUI

/// A media provider that can download a `ClassicAppAccount`'s avatar image.
class ClassicAppMediaLoader: MediaLoaderProtocol {
    let classicAppAccount: ClassicAppAccount
    let urlSession: URLSession
    
    init(classicAppAccount: ClassicAppAccount, urlSession: URLSession = .shared) {
        self.classicAppAccount = classicAppAccount
        self.urlSession = urlSession
    }
    
    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        try await loadMedia(source: source)
    }
    
    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        try await loadMedia(source: source, width: width, height: height)
    }
    
    func loadMediaFileForSource(_ source: MediaSourceProxy, filename: String?) async throws -> MediaFileHandleProxy {
        throw MediaLoaderError.notSupported // Not needed for LoadableImage
    }
    
    // MARK: - Private
    
    private func loadMedia(source: MediaSourceProxy, width: UInt? = nil, height: UInt? = nil) async throws -> Data {
        guard let mxcURL = source.url else {
            MXLog.error("The provided media source is missing the URL")
            throw MediaLoaderError.invalidURL
        }
        
        guard let request = mediaURLRequest(from: mxcURL, width: width, height: height) else {
            MXLog.error("Failed to construct media URL for source: \(mxcURL)")
            throw MediaLoaderError.invalidURL
        }
        
        let (data, response) = try await urlSession.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            MXLog.error("Unexpected response fetching ClassicAppAccount media: \(source.url?.absoluteString ?? "nil")")
            throw MediaLoaderError.unexpectedResponse
        }
        
        return data
    }
    
    /// Constructs an authenticated `URLRequest` to download Matrix media from the homeserver.
    ///
    /// - When `width` and `height` are provided, converts `mxc://{serverName}/{mediaId}` to
    ///   `{homeserverURL}/_matrix/client/v1/media/thumbnail/{serverName}/{mediaId}?width=…&height=…`
    /// - Otherwise converts to `{homeserverURL}/_matrix/client/v1/media/download/{serverName}/{mediaId}`
    ///
    /// Sets the `Authorization: Bearer` header when an access token is provided.
    private func mediaURLRequest(from mxcURL: URL, width: UInt?, height: UInt?) -> URLRequest? {
        guard mxcURL.scheme == "mxc" else { return nil }
        
        let serverName = mxcURL.host() ?? ""
        let mediaID = mxcURL.path().trimmingCharacters(in: CharacterSet(charactersIn: "/"))
        
        guard !serverName.isEmpty, !mediaID.isEmpty else { return nil }
        
        let isThumbnail = width != nil && height != nil
        let endpoint = isThumbnail ? "_matrix/client/v1/media/thumbnail" : "_matrix/client/v1/media/download"
        
        var components = URLComponents(url: classicAppAccount.homeserverURL
            .appending(path: endpoint)
            .appending(path: serverName)
            .appending(path: mediaID), resolvingAgainstBaseURL: false)
        
        if let width, let height {
            components?.queryItems = [
                URLQueryItem(name: "width", value: String(width)),
                URLQueryItem(name: "height", value: String(height))
            ]
        }
        
        guard let url = components?.url else { return nil }
        
        var request = URLRequest(url: url)
        request.setValue("Bearer \(classicAppAccount.accessToken)", forHTTPHeaderField: "Authorization")
        return request
    }
}
