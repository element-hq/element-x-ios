//
// Copyright 2026 Element Creations Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial.
// Please see LICENSE files in the repository root for full details.
//

import Foundation

@preconcurrency import MatrixRustSDK

nonisolated struct ContentScannerProxy: ContentScannerProxyProtocol {
    private let contentScanner: ContentScanner
    /// The client is held weakly for the same reason as in `MediaLoader` - to avoid keeping the
    /// underlying `MatrixRustSDK.Client` alive longer than the owning `ClientProxy`.
    private weak var client: Client?
    
    init(contentScanner: ContentScanner, client: Client) {
        self.contentScanner = contentScanner
        self.client = client
    }
    
    func scan(mediaSource: MediaSourceProxy) async -> Result<Bool, ContentScannerProxyError> {
        guard let client else { return .failure(.missingClient) }
        
        do {
            let response = try await contentScanner.scan(client: client, mediaSource: mediaSource.underlyingSource)
            return .success(response.clean)
        } catch {
            MXLog.error("Failed scanning media content: \(error)")
            return .failure(.sdkError(error))
        }
    }
}
