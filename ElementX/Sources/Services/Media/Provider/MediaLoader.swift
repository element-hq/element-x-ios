//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only
// Please see LICENSE in the repository root for full details.
//

import Combine
import Foundation
import MatrixRustSDK
import UIKit

private final class MediaRequest {
    var continuations: [CheckedContinuation<Data, Error>] = []
}

actor MediaLoader: MediaLoaderProtocol {
    private let client: ClientProtocol
    private var ongoingRequests = [MediaSourceProxy: MediaRequest]()

    init(client: ClientProtocol) {
        self.client = client
    }
    
    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        try await enqueueLoadMediaRequest(forSource: source) {
            try await self.client.getMediaContent(mediaSource: source.underlyingSource)
        }
    }
    
    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        try await enqueueLoadMediaRequest(forSource: source) {
            try await self.client.getMediaThumbnail(mediaSource: source.underlyingSource, width: UInt64(width), height: UInt64(height))
        }
    }
    
    func loadMediaFileForSource(_ source: MediaSourceProxy, body: String?) async throws -> MediaFileHandleProxy {
        let result = try await client.getMediaFile(mediaSource: source.underlyingSource, body: body, mimeType: source.mimeType ?? "application/octet-stream", useCache: true, tempDir: nil)
        
        return MediaFileHandleProxy(handle: result)
    }
    
    // MARK: - Private
    
    private func enqueueLoadMediaRequest(forSource source: MediaSourceProxy, operation: @escaping () async throws -> Data) async throws -> Data {
        if let ongoingRequest = ongoingRequests[source] {
            return try await withCheckedThrowingContinuation { continuation in
                ongoingRequest.continuations.append(continuation)
            }
        }
        
        let ongoingRequest = MediaRequest()
        ongoingRequests[source] = ongoingRequest
        
        defer {
            ongoingRequests[source] = nil
        }
        
        do {
            let result = try await operation()
            
            ongoingRequest.continuations.forEach { $0.resume(returning: result) }
            
            return result
            
        } catch {
            ongoingRequest.continuations.forEach { $0.resume(throwing: error) }
            throw error
        }
    }
}
