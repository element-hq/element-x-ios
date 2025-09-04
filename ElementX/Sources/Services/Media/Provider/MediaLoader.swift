//
// Copyright 2022-2024 New Vector Ltd.
//
// SPDX-License-Identifier: AGPL-3.0-only OR LicenseRef-Element-Commercial
// Please see LICENSE files in the repository root for full details.
//

import Combine
import Foundation
import UIKit

@preconcurrency import MatrixRustSDK

private final class MediaRequest {
    var continuations: [CheckedContinuation<Data, Error>] = []
}

actor MediaLoader: MediaLoaderProtocol {
    // Something is holding onto our MediaProvider (and therefore this MediaLoader) which means
    // when attempting to clear the caches, the SDK's Client hangs around and we end up with 2.
    // I have spent a long time trying to understand what's going on – there's instances of both
    // TimelineViewModel.Context and ComposerToolbarViewModel.Context still hanging around and
    // a closure captures the media provider from both of those as far as I can tell, but I was
    // unable to break the reference. Possibly related to the ElementTextView too.
    //
    // In lieu of the real fix, lets use a weak reference to the Client here so that it can be
    // released and hopefully that will solve our logs files exploding in size when encountering
    // a corrupt/missing database file.
    private weak var client: ClientProtocol?
    private var ongoingRequests = [MediaSourceProxy: MediaRequest]()

    init(client: ClientProtocol) {
        self.client = client
    }
    
    func loadMediaContentForSource(_ source: MediaSourceProxy) async throws -> Data {
        try await enqueueLoadMediaRequest(forSource: source) { [weak client] in
            guard let client else { throw MediaLoaderError.missingClient }
            return try await client.getMediaContent(mediaSource: source.underlyingSource)
        }
    }
    
    func loadMediaThumbnailForSource(_ source: MediaSourceProxy, width: UInt, height: UInt) async throws -> Data {
        try await enqueueLoadMediaRequest(forSource: source) { [weak client] in
            guard let client else { throw MediaLoaderError.missingClient }
            return try await client.getMediaThumbnail(mediaSource: source.underlyingSource, width: UInt64(width), height: UInt64(height))
        }
    }
    
    func loadMediaFileForSource(_ source: MediaSourceProxy, filename: String?) async throws -> MediaFileHandleProxy {
        guard let client else { throw MediaLoaderError.missingClient }
        let result = try await client.getMediaFile(mediaSource: source.underlyingSource,
                                                   filename: filename,
                                                   mimeType: source.mimeType ?? "application/octet-stream",
                                                   useCache: true,
                                                   tempDir: nil)
        
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
